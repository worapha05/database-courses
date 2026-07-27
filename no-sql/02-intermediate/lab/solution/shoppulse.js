import { ObjectId, MongoClient } from 'mongodb';
import Redis from 'ioredis';

const MONGO_URI =
  process.env.MONGO_URI ??
  'mongodb://bootcamp:bootcamp@localhost:27017/bootcamp?authSource=admin&replicaSet=rs0&directConnection=true';
const REDIS_URL = process.env.REDIS_URL ?? 'redis://localhost:6379';

const client = new MongoClient(MONGO_URI);
const redis = new Redis(REDIS_URL);

const CACHE_KEY = 'cache:shoppulse:revenue';
const BOARD_KEY = 'shoppulse:top:units';

async function seed(db) {
  const categories = db.collection('sp_categories');
  const products = db.collection('sp_products');
  const orders = db.collection('sp_orders');

  await Promise.all([categories.deleteMany({}), products.deleteMany({}), orders.deleteMany({})]);
  await redis.del(CACHE_KEY, BOARD_KEY, 'wishlist:vip1', 'wishlist:vip2');

  const apparelId = new ObjectId();
  const homeId = new ObjectId();
  await categories.insertMany([
    { _id: apparelId, name: 'Apparel', slug: 'apparel' },
    { _id: homeId, name: 'Home', slug: 'home' },
  ]);

  const catalog = [
    {
      sku: 'TSHIRT-01',
      name: 'Classic Tee',
      price: 390,
      categoryId: apparelId,
      categoryName: 'Apparel',
    },
    {
      sku: 'HAT-02',
      name: 'Cap',
      price: 250,
      categoryId: apparelId,
      categoryName: 'Apparel',
    },
    {
      sku: 'HOODIE-03',
      name: 'Hoodie',
      price: 890,
      categoryId: apparelId,
      categoryName: 'Apparel',
    },
    {
      sku: 'MUG-04',
      name: 'Mug',
      price: 180,
      categoryId: homeId,
      categoryName: 'Home',
    },
    {
      sku: 'CANDLE-05',
      name: 'Candle',
      price: 220,
      categoryId: homeId,
      categoryName: 'Home',
    },
    {
      sku: 'TOWEL-06',
      name: 'Towel',
      price: 320,
      categoryId: homeId,
      categoryName: 'Home',
    },
  ];

  await products.insertMany(catalog.map(({ categoryName, ...p }) => ({ ...p, active: true })));

  const bySku = Object.fromEntries(catalog.map(p => [p.sku, p]));

  function line(sku, qty) {
    const p = bySku[sku];
    return {
      sku,
      name: p.name,
      qty,
      unitPrice: p.price,
      categoryName: p.categoryName,
    };
  }

  await orders.insertMany([
    {
      orderNo: 'SP-1',
      status: 'paid',
      createdAt: new Date(),
      items: [line('TSHIRT-01', 2), line('HAT-02', 1)],
    },
    {
      orderNo: 'SP-2',
      status: 'paid',
      createdAt: new Date(),
      items: [line('MUG-04', 4), line('CANDLE-05', 1)],
    },
    {
      orderNo: 'SP-3',
      status: 'paid',
      createdAt: new Date(),
      items: [line('HOODIE-03', 1), line('TSHIRT-01', 1)],
    },
    {
      orderNo: 'SP-4',
      status: 'paid',
      createdAt: new Date(),
      items: [line('TOWEL-06', 2), line('HAT-02', 2)],
    },
    {
      orderNo: 'SP-5',
      status: 'paid',
      createdAt: new Date(),
      items: [line('CANDLE-05', 3), line('MUG-04', 1)],
    },
    {
      orderNo: 'SP-6',
      status: 'cancelled',
      createdAt: new Date(),
      items: [line('HOODIE-03', 5)],
    },
  ]);

  return { categories, products, orders, bySku };
}

async function revenueByCategory(orders) {
  return orders
    .aggregate([
      { $match: { status: 'paid' } },
      { $unwind: '$items' },
      {
        $group: {
          _id: '$items.categoryName',
          revenue: {
            $sum: { $multiply: ['$items.qty', '$items.unitPrice'] },
          },
          units: { $sum: '$items.qty' },
        },
      },
      { $project: { _id: 0, category: '$_id', revenue: 1, units: 1 } },
      { $sort: { revenue: -1 } },
    ])
    .toArray();
}

async function topSkus(orders, limit = 10) {
  return orders
    .aggregate([
      { $match: { status: 'paid' } },
      { $unwind: '$items' },
      {
        $group: {
          _id: '$items.sku',
          units: { $sum: '$items.qty' },
          revenue: {
            $sum: { $multiply: ['$items.qty', '$items.unitPrice'] },
          },
        },
      },
      { $sort: { units: -1 } },
      { $limit: limit },
      { $project: { _id: 0, sku: '$_id', units: 1, revenue: 1 } },
    ])
    .toArray();
}

async function rebuildLeaderboard(orders) {
  await redis.del(BOARD_KEY);
  const rows = await topSkus(orders, 100);
  if (rows.length) {
    const args = [];
    for (const r of rows) args.push(r.units, r.sku);
    await redis.zadd(BOARD_KEY, ...args);
  }
}

async function getRevenueReport(orders) {
  const cached = await redis.get(CACHE_KEY);
  if (cached) {
    console.log('[report HIT]');
    try {
      return JSON.parse(cached);
    } catch {
      console.log('[report cache corrupted, fallback to DB]');
    }
  }

  console.log('[report MISS]');
  const report = await revenueByCategory(orders);
  await redis.set(CACHE_KEY, JSON.stringify(report), 'EX', 120);
  return report;
}

async function recordOrder(orders, bySku, orderNo, itemSpecs) {
  const items = itemSpecs.map(({ sku, qty }) => {
    const p = bySku[sku];
    return {
      sku,
      name: p.name,
      qty,
      unitPrice: p.price,
      categoryName: p.categoryName,
    };
  });

  const doc = {
    orderNo,
    status: 'paid',
    createdAt: new Date(),
    items,
  };
  await orders.insertOne(doc);

  for (const it of items) {
    await redis.zincrby(BOARD_KEY, it.qty, it.sku);
  }
  await redis.del(CACHE_KEY);
  console.log('recorded', orderNo, '+ invalidated report cache');
}

async function main() {
  try {
    await client.connect();
    const db = client.db('bootcamp');
    const { orders, bySku } = await seed(db);

    await rebuildLeaderboard(orders);

    console.log('revenue:', await getRevenueReport(orders));
    console.log('revenue:', await getRevenueReport(orders));

    console.log('top5 zset:', await redis.zrevrange(BOARD_KEY, 0, 4, 'WITHSCORES'));
    console.log('agg top skus:', await topSkus(orders, 5));

    await redis.sadd('wishlist:vip1', 'TSHIRT-01', 'HAT-02', 'MUG-04');
    await redis.sadd('wishlist:vip2', 'HAT-02', 'CANDLE-05', 'TSHIRT-01');
    console.log('wishlist intersect:', await redis.sinter('wishlist:vip1', 'wishlist:vip2'));

    await recordOrder(orders, bySku, 'SP-7', [
      { sku: 'TSHIRT-01', qty: 3 },
      { sku: 'TOWEL-06', qty: 1 },
    ]);

    console.log('revenue after new order:', await getRevenueReport(orders));
    console.log('top5 after:', await redis.zrevrange(BOARD_KEY, 0, 4, 'WITHSCORES'));
  } catch (err) {
    console.error(err);
    process.exitCode = 1;
  } finally {
    redis.disconnect();
    await client.close();
  }
}

main();
