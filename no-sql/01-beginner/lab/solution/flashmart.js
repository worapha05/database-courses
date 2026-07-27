import { MongoClient } from 'mongodb';
import Redis from 'ioredis';

const MONGO_URI =
  process.env.MONGO_URI ??
  'mongodb://bootcamp:bootcamp@localhost:27017/bootcamp?authSource=admin&replicaSet=rs0&directConnection=true';
const REDIS_URL = process.env.REDIS_URL ?? 'redis://localhost:6379';

const client = new MongoClient(MONGO_URI);
const redis = new Redis(REDIS_URL);

async function seed(db) {
  const products = db.collection('fm_products');
  const orders = db.collection('fm_orders');

  await products.deleteMany({});
  await orders.deleteMany({});
  await products.createIndex({ sku: 1 }, { unique: true });
  await orders.createIndex({ orderNo: 1 }, { unique: true });

  await products.insertMany([
    {
      sku: 'TSHIRT-01',
      name: 'Classic Tee',
      price: 390,
      stock: 25,
      tags: ['apparel', 'cotton'],
      active: true,
      createdAt: new Date(),
    },
    {
      sku: 'HAT-02',
      name: 'Cap',
      price: 250,
      stock: 40,
      tags: ['apparel'],
      active: true,
      createdAt: new Date(),
    },
    {
      sku: 'MUG-03',
      name: 'Logo Mug',
      price: 180,
      stock: 15,
      tags: ['home'],
      active: true,
      createdAt: new Date(),
    },
    {
      sku: 'BAG-04',
      name: 'Tote Bag',
      price: 450,
      stock: 8,
      tags: ['accessories'],
      active: true,
      createdAt: new Date(),
    },
    {
      sku: 'SOCK-05',
      name: 'Crew Socks',
      price: 120,
      stock: 100,
      tags: ['apparel'],
      active: true,
      createdAt: new Date(),
    },
  ]);

  const mid = await products
    .find({ active: true, price: { $gte: 100, $lte: 500 } })
    .project({ _id: 0, sku: 1, name: 1, price: 1 })
    .toArray();
  console.log('active mid-price products:', mid);

  return { products, orders };
}

async function createOrder(products, orders) {
  const tee = await products.findOne({ sku: 'TSHIRT-01' });
  const hat = await products.findOne({ sku: 'HAT-02' });

  const items = [
    { sku: tee.sku, name: tee.name, qty: 2, unitPrice: tee.price },
    { sku: hat.sku, name: hat.name, qty: 1, unitPrice: hat.price },
  ];
  const total = items.reduce((s, i) => s + i.qty * i.unitPrice, 0);

  await orders.insertOne({
    orderNo: 'ORD-1001',
    customerEmail: 'mira@ex.com',
    items,
    total,
    status: 'pending',
    createdAt: new Date(),
  });

  await products.updateOne({ sku: 'TSHIRT-01' }, { $inc: { stock: -2 } });
  await products.updateOne({ sku: 'HAT-02' }, { $inc: { stock: -1 } });
  await redis.del('cache:product:TSHIRT-01', 'cache:product:HAT-02');

  console.log('order created total=', total);
}

async function softCancel(orders) {
  await orders.updateOne({ orderNo: 'ORD-1001' }, { $set: { status: 'cancelled' } });
  console.log('order soft-cancelled');
}

async function setupSession() {
  const key = 'session:user:mira@ex.com';
  await redis.hset(key, {
    cartId: 'cart-9',
    role: 'customer',
    lastSku: 'TSHIRT-01',
  });
  await redis.expire(key, 1800);
  console.log('session:', await redis.hgetall(key), 'ttl=', await redis.ttl(key));
}

async function getProduct(products, sku) {
  const cacheKey = `cache:product:${sku}`;
  const cached = await redis.get(cacheKey).catch(() => null);
  if (cached) {
    redis.incr(`metrics:product:views:${sku}`).catch(() => {});
    console.log(`[HIT] ${sku}`);
    try {
      return JSON.parse(cached);
    } catch {
      return null;
    }
  }

  const doc = await products.findOne(
    { sku, active: true },
    { projection: { _id: 0, sku: 1, name: 1, price: 1, stock: 1 } },
  );
  if (!doc) {
    console.log(`[MISS-EMPTY] ${sku}`);
    return null;
  }

  await redis.set(cacheKey, JSON.stringify(doc), 'EX', 60).catch(() => {});
  await redis.incr(`metrics:product:views:${sku}`).catch(() => {});
  console.log(`[MISS→SET] ${sku}`);
  return doc;
}

async function main() {
  try {
    await client.connect();
    const db = client.db('bootcamp');
    const { products, orders } = await seed(db);

    await createOrder(products, orders);
    await softCancel(orders);
    await setupSession();

    await getProduct(products, 'TSHIRT-01');
    await getProduct(products, 'TSHIRT-01');

    await products.updateOne({ sku: 'TSHIRT-01' }, { $inc: { stock: -1 } });
    await redis.del('cache:product:TSHIRT-01');
    await getProduct(products, 'TSHIRT-01');

    console.log('views:', await redis.get('metrics:product:views:TSHIRT-01'));
  } catch (err) {
    console.error(err);
    process.exitCode = 1;
  } finally {
    redis.disconnect();
    await client.close();
  }
}

main();
