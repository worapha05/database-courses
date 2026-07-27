import { withRedis } from '../../../.infra/lib/connections.js';

const STREAM = 'orders:stream';
const GROUP = 'workers';

await withRedis(async redis => {
  await redis.del(STREAM);

  try {
    await redis.xgroup('CREATE', STREAM, GROUP, '$', 'MKSTREAM');
  } catch (e) {
    if (!String(e.message).includes('BUSYGROUP')) throw e;
  }

  // Producer: XADD
  for (let i = 1; i <= 5; i++) {
    const id = await redis.xadd(STREAM, '*', 'orderNo', `ORD-S-${i}`, 'total', String(100 * i));
    console.log('XADD', id);
  }

  // Consumer: XREADGROUP
  const results = await redis.xreadgroup(
    'GROUP',
    GROUP,
    'consumer-1',
    'COUNT',
    10,
    'STREAMS',
    STREAM,
    '>',
  );

  if (results) {
    for (const [, messages] of results) {
      for (const [id, fields] of messages) {
        const data = {};
        for (let i = 0; i < fields.length; i += 2) {
          data[fields[i]] = fields[i + 1];
        }
        console.log('process', id, data);
        await redis.xack(STREAM, GROUP, id);
      }
    }
  }

  console.log('pending after ACK:', await redis.xpending(STREAM, GROUP));
});
