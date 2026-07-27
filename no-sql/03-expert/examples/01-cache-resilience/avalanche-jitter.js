import { withRedis } from '../../../.infra/lib/connections.js';

function ttlWithJitter(baseSec, jitterSec) {
  return baseSec + Math.floor(Math.random() * (jitterSec + 1));
}

await withRedis(async redis => {
  const keys = Array.from({ length: 10 }, (_, i) => `cache:hot:item:${i}`);
  await redis.del(...keys);

  for (const key of keys) {
    const ttl = ttlWithJitter(60, 30);
    await redis.set(key, JSON.stringify({ ok: true }), 'EX', ttl);
    console.log(key, 'TTL=', ttl);
  }

  console.log('แนวคิด: กระจายเวลาหมดอายุ เพื่อไม่ให้ DB โดนยิงพร้อมกัน');
});
