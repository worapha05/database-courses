import { withRedis } from '../../../.infra/lib/connections.js';

let dbLoads = 0;

async function expensiveLoader() {
  dbLoads += 1;
  await new Promise(r => setTimeout(r, 100));
  return { sku: 'TSHIRT-01', price: 390, loadedAt: Date.now() };
}

async function getWithSingleflight(redis, key, loader, ttlSec = 30) {
  const hit = await redis.get(key);

  if (hit) {
    try {
      return { source: 'cache', value: JSON.parse(hit) };
    } catch {
      await redis.del(key);
    }
  }

  const lockKey = `lock:${key}`;
  const gotLock = await redis.set(lockKey, '1', 'EX', 5, 'NX');

  if (gotLock) {
    try {
      const value = await loader();
      await redis.set(key, JSON.stringify(value), 'EX', ttlSec);
      return { source: 'db-leader', value };
    } finally {
      await redis.del(lockKey);
    }
  }

  for (let i = 0; i < 20; i++) {
    await new Promise(r => setTimeout(r, 20));
    const retry = await redis.get(key);

    if (retry) {
      try {
        return { source: 'cache-wait', value: JSON.parse(retry) };
      } catch {
        continue;
      }
    }
  }

  return { source: 'db-fallback', value: await loader() };
}

await withRedis(async redis => {
  const key = 'cache:stampede:product:TSHIRT-01';
  await redis.del(key, `lock:${key}`);

  const results = await Promise.all(
    Array.from({ length: 20 }, () => getWithSingleflight(redis, key, expensiveLoader)),
  );

  const sources = results.reduce((acc, r) => {
    acc[r.source] = (acc[r.source] ?? 0) + 1;
    return acc;
  }, {});

  console.log('sources:', sources);
  console.log('dbLoads (should be ~1, maybe +few fallback):', dbLoads);
});
