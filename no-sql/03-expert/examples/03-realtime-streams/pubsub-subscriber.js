import { createRedis } from '../../../.infra/lib/connections.js';

const redis = createRedis();
const channel = 'orders:events';

redis.subscribe(channel, (err, count) => {
  if (err) {
    console.error('subscribe error:', err);
    process.exit(1);
  }
  console.log(`subscribed to ${count} channel(s), waiting on ${channel}...`);
});

redis.on('message', (ch, message) => {
  console.log(`[${ch}]`, message);
});

process.on('SIGINT', () => {
  console.log('\nshutting down subscriber');
  redis.disconnect();
  process.exit(0);
});
