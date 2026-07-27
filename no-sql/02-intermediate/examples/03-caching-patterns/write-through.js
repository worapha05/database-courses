import { withMongo, withRedis } from '../../../.infra/lib/connections.js';

await withMongo('bootcamp', async db => {
  const products = db.collection('cache_products_wt');
  await products.deleteMany({});

  await withRedis(async redis => {
    async function writeThroughUpsert(doc) {
      await products.updateOne({ sku: doc.sku }, { $set: doc }, { upsert: true });
      await redis.set(`cache:wt:product:${doc.sku}`, JSON.stringify(doc), 'EX', 60);
      console.log('write-through complete:', doc.sku);
    }

    async function read(sku) {
      const raw = await redis.get(`cache:wt:product:${sku}`);
      if (raw) {
        console.log('read from cache');
        try {
          return JSON.parse(raw);
        } catch {
          console.log('cache corrupted, fallback to DB');
        }
      }

      console.log('cache empty -> DB fallback');
      return products.findOne({ sku }, { projection: { _id: 0 } });
    }

    await writeThroughUpsert({
      sku: 'HAT-02',
      name: 'Cap',
      price: 250,
      stock: 40,
    });
    console.log(await read('HAT-02'));

    await writeThroughUpsert({
      sku: 'HAT-02',
      name: 'Cap',
      price: 269,
      stock: 39,
    });
    console.log(await read('HAT-02'));
  });
});
