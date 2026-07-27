import { withMongo, withRedis } from '../../../.infra/lib/connections.js';

await withMongo('bootcamp', async db => {
  const products = db.collection('cache_products');
  await products.deleteMany({});
  await products.insertOne({
    sku: 'TSHIRT-01',
    name: 'Classic Tee',
    price: 390,
    stock: 25,
  });

  await withRedis(async redis => {
    async function getProduct(sku) {
      const cacheKey = `cache:aside:product:${sku}`;
      const hit = await redis.get(cacheKey);
      if (hit) {
        console.log('HIT');
        try {
          return JSON.parse(hit);
        } catch {
          console.log('cache corrupted, fallback to DB');
        }
      }

      console.log('MISS -> load DB');
      const doc = await products.findOne({ sku }, { projection: { _id: 0 } });
      if (doc) {
        await redis.set(cacheKey, JSON.stringify(doc), 'EX', 30);
      }
      return doc;
    }

    async function updatePrice(sku, price) {
      await products.updateOne({ sku }, { $set: { price } });
      await redis.del(`cache:aside:product:${sku}`);
      console.log('DB updated + cache invalidated');
    }

    // Test flow
    console.log(await getProduct('TSHIRT-01'));
    console.log(await getProduct('TSHIRT-01'));

    await updatePrice('TSHIRT-01', 420);
    console.log(await getProduct('TSHIRT-01'));
  });
});
