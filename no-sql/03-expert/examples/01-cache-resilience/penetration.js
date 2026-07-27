import { withMongo, withRedis } from '../../../.infra/lib/connections.js';

await withMongo('bootcamp', async db => {
  const products = db.collection('pen_products');
  await products.deleteMany({});
  await products.insertOne({ sku: 'REAL-01', name: 'Exists' });

  await withRedis(async redis => {
    async function getProduct(sku) {
      const key = `cache:pen:product:${sku}`;
      const cached = await redis.get(key);

      if (cached === 'NULL') {
        console.log(sku, '→ cached NULL');
        return null;
      }

      if (cached) {
        console.log(sku, '→ cache HIT');
        try {
          return JSON.parse(cached);
        } catch {
          console.log(sku, '→ cache parse error, refetching');
        }
      }

      const doc = await products.findOne({ sku }, { projection: { _id: 0 } });

      if (!doc) {
        await redis.set(key, 'NULL', 'EX', 30);
        console.log(sku, '→ DB miss, cached NULL');
        return null;
      }

      await redis.set(key, JSON.stringify(doc), 'EX', 60);
      console.log(sku, '→ DB hit, cached');
      return doc;
    }

    await getProduct('FAKE-999');
    await getProduct('FAKE-999');
    await getProduct('REAL-01');
  });
});
