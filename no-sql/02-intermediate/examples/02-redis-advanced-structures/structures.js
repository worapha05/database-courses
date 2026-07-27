import { withRedis } from '../../../.infra/lib/connections.js';

await withRedis(async redis => {
  // --- List: order event queue + recent feed ---
  await redis.del('queue:orders', 'feed:user:mira');
  await redis.lpush('queue:orders', 'ORD-1', 'ORD-2', 'ORD-3');
  console.log('RPOP queue:', await redis.rpop('queue:orders'));

  await redis.lpush('feed:user:mira', 'liked:HAT-02', 'bought:TSHIRT-01', 'viewed:MUG-03');
  await redis.ltrim('feed:user:mira', 0, 49);
  console.log('recent feed:', await redis.lrange('feed:user:mira', 0, 9));

  // --- Set: wishlists ---
  await redis.del('wishlist:mira', 'wishlist:bob');
  await redis.sadd('wishlist:mira', 'TSHIRT-01', 'HAT-02', 'MUG-03');
  await redis.sadd('wishlist:bob', 'HAT-02', 'BAG-04');
  console.log('shared wishlist:', await redis.sinter('wishlist:mira', 'wishlist:bob'));
  console.log('mira has TSHIRT-01?', await redis.sismember('wishlist:mira', 'TSHIRT-01'));

  // --- Sorted Set: weekly leaderboard ---
  const board = 'leaderboard:weekly';
  await redis.del(board);
  await redis.zadd(board, 1500, 'mira', 1200, 'bob', 900, 'cara');
  await redis.zincrby(board, 200, 'bob');
  console.log('top 3:', await redis.zrevrange(board, 0, 2, 'WITHSCORES'));
  console.log('mira rank (0-based from top):', await redis.zrevrank(board, 'mira'));
});
