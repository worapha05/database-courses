import { withMongo } from '../../../.infra/lib/connections.js';

await withMongo('bootcamp', async db => {
  const products = db.collection('products_beginner');

  await products.deleteMany({});
  await products.createIndex({ sku: 1 }, { unique: true });

  // CREATE
  const inserted = await products.insertOne({
    sku: 'TSHIRT-01',
    name: 'Classic Tee',
    price: 390,
    tags: ['apparel', 'cotton'],
    attributes: { color: 'navy', size: 'M' },
    stock: 25,
    active: true,
    createdAt: new Date(),
  });
  console.log('insertOne _id:', inserted.insertedId.toString());

  await products.insertMany([
    {
      sku: 'HAT-02',
      name: 'Cap',
      price: 250,
      tags: ['apparel', 'accessories'],
      stock: 40,
      active: true,
      createdAt: new Date(),
    },
    {
      sku: 'MUG-03',
      name: 'Logo Mug',
      price: 180,
      tags: ['home'],
      stock: 0,
      active: false,
      createdAt: new Date(),
    },
  ]);

  // READ — query selectors
  const midPrice = await products
    .find({ price: { $gte: 200, $lte: 400 }, active: true })
    .project({ _id: 0, sku: 1, name: 1, price: 1 })
    .toArray();
  console.log('find mid-price active:', midPrice);

  const cotton = await products.findOne({ tags: 'cotton' });
  console.log('findOne cotton:', cotton?.sku);

  const nested = await products.findOne({ 'attributes.color': 'navy' });
  console.log('nested color navy:', nested?.sku);

  // UPDATE — ใช้ operator แทน replaceOne
  const updated = await products.updateOne(
    { sku: 'TSHIRT-01' },
    {
      $set: { price: 420 },
      $inc: { stock: -1 },
      $push: { tags: 'bestseller' },
    },
  );
  console.log('updateOne matched/modified:', updated.matchedCount, updated.modifiedCount);

  const after = await products.findOne(
    { sku: 'TSHIRT-01' },
    { projection: { _id: 0, price: 1, stock: 1, tags: 1 } },
  );
  console.log('after update:', after);

  // Soft DELETE — ดีกว่า hard delete สำหรับข้อมูลธุรกิจ
  await products.updateOne({ sku: 'MUG-03' }, { $set: { deletedAt: new Date(), active: false } });
  const visible = await products.countDocuments({
    deletedAt: { $exists: false },
  });
  console.log('visible (not soft-deleted):', visible);

  // Hard DELETE — ใช้ sparingly
  const deleted = await products.deleteOne({ sku: 'HAT-02' });
  console.log('deleteOne deletedCount:', deleted.deletedCount);
});
