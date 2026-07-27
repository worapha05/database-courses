import { withRedis } from '../../../.infra/lib/connections.js';

await withRedis(async redis => {
  const payload = {
    orderNo: 'ORD-LIVE-1',
    total: 1030,
    status: 'paid',
    at: new Date().toISOString(),
  };

  const receivers = await redis.publish('orders:events', JSON.stringify(payload));
  console.log('published to', receivers, 'subscriber(s)');
});
