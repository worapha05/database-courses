import { ObjectId } from 'mongodb';
import { withMongo } from '../../../.infra/lib/connections.js';

await withMongo('bootcamp', async db => {
  const categories = db.collection('model_categories');
  const products = db.collection('model_products');
  const orders = db.collection('model_orders');

  await Promise.all([categories.deleteMany({}), products.deleteMany({}), orders.deleteMany({})]);

  // Reference: category เป็น master data ที่แชร์
  const apparelId = new ObjectId();
  await categories.insertOne({
    _id: apparelId,
    name: 'Apparel',
    slug: 'apparel',
  });

  await products.insertOne({
    sku: 'TSHIRT-01',
    name: 'Classic Tee',
    price: 390,
    categoryId: apparelId,
  });

  // Embed: order items เป็น snapshot ของออเดอร์นั้น
  await orders.insertOne({
    orderNo: 'ORD-9001',
    customerEmail: 'mira@ex.com',
    items: [
      {
        sku: 'TSHIRT-01',
        name: 'Classic Tee',
        qty: 2,
        unitPrice: 390,
        categoryName: 'Apparel',
      },
    ],
    total: 780,
    status: 'paid',
    createdAt: new Date(),
  });

  // อ่าน product + category ผ่าน $lookup
  const productWithCategory = await products
    .aggregate([
      { $match: { sku: 'TSHIRT-01' } },
      {
        $lookup: {
          from: 'model_categories',
          localField: 'categoryId',
          foreignField: '_id',
          as: 'category',
        },
      },
      { $unwind: '$category' },
      {
        $project: {
          _id: 0,
          sku: 1,
          name: 1,
          price: 1,
          category: '$category.name',
        },
      },
    ])
    .toArray();

  console.log('product (referenced category):', productWithCategory[0]);

  // อ่านออเดอร์ — ไม่ต้อง join เพราะ embed แล้ว
  const order = await orders.findOne({ orderNo: 'ORD-9001' }, { projection: { _id: 0 } });
  console.log('order (embedded items):', order);

  // เปลี่ยนชื่อหมวดใน master — ออเดอร์เก่ายังคง snapshot เดิม
  await categories.updateOne({ _id: apparelId }, { $set: { name: 'Clothing' } });

  const oldOrder = await orders.findOne({ orderNo: 'ORD-9001' });
  console.log('order snapshot category still:', oldOrder.items[0].categoryName);
  console.log('master category now:', (await categories.findOne({ _id: apparelId })).name);
});
