import { withRedis } from '../../../.infra/lib/connections.js';

await withRedis(async redis => {
  // SET + GET พร้อม TTL
  await redis.set(
    'cache:product:TSHIRT-01',
    JSON.stringify({ name: 'Classic Tee', price: 390 }),
    'EX',
    60,
  );
  const raw = await redis.get('cache:product:TSHIRT-01');
  let data;
  try {
    data = JSON.parse(raw);
  } catch {
    data = null;
  }
  console.log('GET cache:', data);

  // Atomic counters
  await redis.del('metrics:pageviews:home');
  console.log('INCR #1:', await redis.incr('metrics:pageviews:home'));
  console.log('INCR #2:', await redis.incr('metrics:pageviews:home'));
  console.log('INCRBY 10:', await redis.incrby('metrics:pageviews:home', 10));

  // TTL lifecycle
  await redis.set('session:user:42', 'mira-token');
  await redis.expire('session:user:42', 5);
  console.log('TTL after EXPIRE 5s:', await redis.ttl('session:user:42'));

  // SET NX — set เฉพาะเมื่อยังไม่มี key (lock / first-write)
  const nx = await redis.set('lock:order:1001', 'worker-a', 'EX', 10, 'NX');
  console.log('SET NX first:', nx);

  const nx2 = await redis.set('lock:order:1001', 'worker-b', 'EX', 10, 'NX');
  console.log('SET NX second:', nx2);

  await redis.del('cache:product:TSHIRT-01');
  console.log('after DEL exists:', await redis.exists('cache:product:TSHIRT-01'));
});
