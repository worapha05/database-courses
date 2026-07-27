import { MongoClient } from 'mongodb';
import { createRedis } from '../../../.infra/lib/connections.js';

const MONGO_URI =
  process.env.MONGO_URI ??
  'mongodb://bootcamp:bootcamp@localhost:27017/bootcamp?authSource=admin&replicaSet=rs0&directConnection=true';

const client = new MongoClient(MONGO_URI);
const redis = createRedis();

function isChangeStreamUnsupported(err) {
  const msg = String(err?.message ?? err);
  return (
    msg.includes('$changeStream stage is only supported on replica sets') ||
    msg.includes('not a member of a replica set') ||
    err?.code === 40573
  );
}

async function main() {
  await client.connect();
  const orders = client.db('bootcamp').collection('rt_orders');

  const stream = orders.watch([{ $match: { operationType: { $in: ['insert', 'update'] } } }], {
    fullDocument: 'updateLookup',
  });

  console.log('watching rt_orders... insert a doc to see events');

  const insertTimer = setTimeout(async () => {
    try {
      await orders.insertOne({
        orderNo: `RT-${Date.now()}`,
        status: 'paid',
        total: 500,
        createdAt: new Date(),
      });
    } catch (err) {
      if (!isChangeStreamUnsupported(err)) {
        console.error('demo insert failed:', err.message);
      }
    }
  }, 500);

  const timeout = setTimeout(() => {
    console.log('timeout — closing');
    stream.close().catch(() => {});
  }, 8000);

  try {
    for await (const event of stream) {
      console.log('change:', event.operationType, event.documentKey);

      if (event.fullDocument) {
        await redis.xadd(
          'orders:stream',
          '*',
          'orderNo',
          event.fullDocument.orderNo ?? '',
          'source',
          'change-stream',
        );
        await redis.publish('orders:events', JSON.stringify(event.fullDocument));
      }

      clearTimeout(timeout);
      break;
    }
  } catch (err) {
    clearTimeout(insertTimer);
    clearTimeout(timeout);
    await stream.close().catch(() => {});

    if (isChangeStreamUnsupported(err)) {
      console.error('Change Stream ใช้ไม่ได้กับ deployment ปัจจุบัน:', err.message);
      console.error('→ รัน docker compose ที่เปิด --replSet rs0 (ค่าเริ่มต้นของ bootcamp นี้)');
      console.error('→ หรือใช้ Redis Streams/PubSub เป็น event bus แทนในระหว่างเรียน');
      return;
    }
    throw err;
  } finally {
    clearTimeout(insertTimer);
    clearTimeout(timeout);
  }
}

main()
  .catch(e => {
    console.error(e);
    process.exitCode = 1;
  })
  .finally(async () => {
    redis.disconnect();
    await client.close().catch(() => {});
  });
