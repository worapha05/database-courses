import { MongoClient } from 'mongodb';
import Redis from 'ioredis';

const MONGO_URI =
  process.env.MONGO_URI ??
  'mongodb://bootcamp:bootcamp@localhost:27017/bootcamp?authSource=admin&replicaSet=rs0&directConnection=true';
const REDIS_URL = process.env.REDIS_URL ?? 'redis://localhost:6379';

const client = new MongoClient(MONGO_URI);
const redis = new Redis(REDIS_URL);

let dbLoads = 0;

function ttlWithJitter(base = 60, jitter = 30) {
  return base + Math.floor(Math.random() * (jitter + 1));
}

async function getProduct(products, sku) {
  const key = `cache:fm:product:${sku}`;
  const cached = await redis.get(key);

  if (cached === 'NULL') return null;

  if (cached) {
    try {
      return JSON.parse(cached);
    } catch {
      await redis.del(key);
    }
  }

  const lockKey = `lock:${key}`;
  const gotLock = await redis.set(lockKey, '1', 'EX', 5, 'NX');

  if (gotLock) {
    try {
      dbLoads += 1;
      const doc = await products.findOne(
        { sku, active: true },
        {
          projection: {
            _id: 0,
            sku: 1,
            name: 1,
            price: 1,
            stock: 1,
          },
        },
      );

      if (!doc) {
        await redis.set(key, 'NULL', 'EX', 30);
        return null;
      }

      await redis.set(key, JSON.stringify(doc), 'EX', ttlWithJitter());
      return doc;
    } finally {
      await redis.del(lockKey);
    }
  }

  for (let i = 0; i < 25; i++) {
    await new Promise(r => setTimeout(r, 20));
    const retry = await redis.get(key);

    if (retry === 'NULL') return null;

    if (retry) {
      try {
        return JSON.parse(retry);
      } catch {
        continue;
      }
    }
  }

  dbLoads += 1;
  return products.findOne(
    { sku },
    {
      projection: {
        _id: 0,
        sku: 1,
        name: 1,
        price: 1,
        stock: 1,
      },
    },
  );
}

async function seedProducts(db) {
  const products = db.collection('fm_scale_products');
  await products.deleteMany({});
  await products.createIndex({ sku: 1 }, { unique: true });
  await products.insertMany([
    {
      sku: 'TSHIRT-01',
      name: 'Classic Tee',
      price: 390,
      stock: 500,
      active: true,
    },
    {
      sku: 'HAT-02',
      name: 'Cap',
      price: 250,
      stock: 300,
      active: true,
    },
  ]);
  return products;
}

async function seedAndExplainOrders(db) {
  const orders = db.collection('fm_scale_orders');
  await orders.deleteMany({});
  try {
    await orders.dropIndexes();
  } catch {
    /* empty */
  }

  const docs = [];
  for (let i = 0; i < 2500; i++) {
    docs.push({
      orderNo: `FM-${i}`,
      status: i % 6 === 0 ? 'cancelled' : 'paid',
      total: 100 + (i % 40) * 15,
      createdAt: new Date(Date.UTC(2026, 6, 1 + (i % 28))),
      note: i % 11 === 0 ? 'flash sale priority packing' : 'standard',
      location: {
        type: 'Point',
        coordinates: [100.5 + (i % 30) * 0.01, 13.7 + (i % 20) * 0.01],
      },
      items: [
        {
          sku: i % 2 === 0 ? 'TSHIRT-01' : 'HAT-02',
          qty: 1 + (i % 3),
        },
      ],
    });
  }
  await orders.insertMany(docs);

  async function explainLabel(label) {
    const stats = await orders
      .find({
        status: 'paid',
        createdAt: { $gte: new Date('2026-07-10') },
      })
      .sort({ createdAt: -1 })
      .explain('executionStats');
    const es = stats.executionStats;
    console.log(
      `[explain ${label}] stage=${es.executionStages?.stage} examined=${es.totalDocsExamined} returned=${es.nReturned}`,
    );
  }

  await explainLabel('BEFORE index');
  await orders.createIndex({ status: 1, createdAt: -1, total: 1 });
  await orders.createIndex({ note: 'text' });
  await orders.createIndex({ location: '2dsphere' });
  await explainLabel('AFTER compound index');

  return orders;
}

async function liveOpsPipeline(orders) {
  const STREAM = 'orders:live';
  const GROUP = 'live-workers';
  const BOARD = 'flashmart:live:top';

  await redis.del(STREAM, BOARD);
  try {
    await redis.xgroup('CREATE', STREAM, GROUP, '$', 'MKSTREAM');
  } catch (e) {
    if (!String(e.message).includes('BUSYGROUP')) throw e;
  }

  const fresh = {
    orderNo: `FM-LIVE-${Date.now()}`,
    status: 'paid',
    createdAt: new Date(),
    items: [
      { sku: 'TSHIRT-01', qty: 5 },
      { sku: 'HAT-02', qty: 2 },
    ],
  };
  await orders.insertOne(fresh);

  for (const it of fresh.items) {
    const id = await redis.xadd(
      STREAM,
      '*',
      'orderNo',
      fresh.orderNo,
      'sku',
      it.sku,
      'qty',
      String(it.qty),
    );
    console.log('XADD', id, it);
  }

  await redis.publish(
    'orders:events',
    JSON.stringify({ orderNo: fresh.orderNo, items: fresh.items }),
  );

  const batch = await redis.xreadgroup(
    'GROUP',
    GROUP,
    'worker-1',
    'COUNT',
    20,
    'STREAMS',
    STREAM,
    '>',
  );

  if (batch) {
    for (const [, messages] of batch) {
      for (const [id, fields] of messages) {
        const data = {};
        for (let i = 0; i < fields.length; i += 2) {
          data[fields[i]] = fields[i + 1];
        }
        await redis.zincrby(BOARD, Number(data.qty), data.sku);
        await redis.xack(STREAM, GROUP, id);
      }
    }
  }

  console.log('live top:', await redis.zrevrange(BOARD, 0, 9, 'WITHSCORES'));
}

async function main() {
  try {
    await client.connect();
    const db = client.db('bootcamp');

    const products = await seedProducts(db);
    await redis.del('cache:fm:product:TSHIRT-01', 'lock:cache:fm:product:TSHIRT-01');

    dbLoads = 0;
    const concurrent = await Promise.all(
      Array.from({ length: 20 }, () => getProduct(products, 'TSHIRT-01')),
    );
    console.log('concurrent results:', concurrent.length, 'dbLoads=', dbLoads);

    console.log('fake sku:', await getProduct(products, 'NO-SUCH'));
    console.log('fake sku again:', await getProduct(products, 'NO-SUCH'));

    await seedAndExplainOrders(db);
    const orders = db.collection('fm_scale_orders');
    await liveOpsPipeline(orders);

    console.log('\nดูบันทึก HA ที่ 03-expert/lab/solution/HA.md');
  } catch (err) {
    console.error(err);
    process.exitCode = 1;
  } finally {
    redis.disconnect();
    await client.close();
  }
}

main();
