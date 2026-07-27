import { withRedis } from '../../../.infra/lib/connections.js';

await withRedis(async redis => {
  const key = 'session:user:42';
  await redis.del(key);

  await redis.hset(key, {
    name: 'Mira',
    role: 'customer',
    cartId: 'cart-9',
    loginCount: 0,
  });
  await redis.expire(key, 1800);

  console.log('role:', await redis.hget(key, 'role'));
  console.log('loginCount:', await redis.hincrby(key, 'loginCount', 1));
  console.log('HGETALL:', await redis.hgetall(key));

  await redis.hdel(key, 'cartId');
  console.log('after HDEL cartId:', await redis.hgetall(key));
  console.log('TTL:', await redis.ttl(key));
});
