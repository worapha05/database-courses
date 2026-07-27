import { withMongo } from '../../../.infra/lib/connections.js';

await withMongo('bootcamp', async db => {
  const products = db.collection('agg_products');
  const orders = db.collection('agg_orders');

  await products.deleteMany({});
  await orders.deleteMany({});

  await products.insertMany([
    { sku: 'TSHIRT-01', name: 'Classic Tee', category: 'apparel', price: 390 },
    { sku: 'HAT-02', name: 'Cap', category: 'apparel', price: 250 },
    { sku: 'MUG-03', name: 'Logo Mug', category: 'home', price: 180 },
  ]);

  await orders.insertMany([
    {
      orderNo: 'ORD-1',
      status: 'paid',
      createdAt: new Date('2026-07-01'),
      items: [
        { sku: 'TSHIRT-01', qty: 2, unitPrice: 390 },
        { sku: 'HAT-02', qty: 1, unitPrice: 250 },
      ],
    },
    {
      orderNo: 'ORD-2',
      status: 'paid',
      createdAt: new Date('2026-07-05'),
      items: [
        { sku: 'MUG-03', qty: 3, unitPrice: 180 },
        { sku: 'TSHIRT-01', qty: 1, unitPrice: 390 },
      ],
    },
    {
      orderNo: 'ORD-3',
      status: 'cancelled',
      createdAt: new Date('2026-07-06'),
      items: [{ sku: 'HAT-02', qty: 2, unitPrice: 250 }],
    },
  ]);

  // รายงานยอดขายตามหมวด ($match ก่อน $unwind เพื่อลดเอกสาร)
  const revenueByCategory = await orders
    .aggregate([
      { $match: { status: 'paid' } },
      { $unwind: '$items' },
      {
        $lookup: {
          from: 'agg_products',
          localField: 'items.sku',
          foreignField: 'sku',
          as: 'product',
        },
      },
      { $unwind: '$product' },
      {
        $group: {
          _id: '$product.category',
          revenue: {
            $sum: { $multiply: ['$items.qty', '$items.unitPrice'] },
          },
          units: { $sum: '$items.qty' },
          orders: { $addToSet: '$orderNo' },
        },
      },
      {
        $project: {
          _id: 0,
          category: '$_id',
          revenue: 1,
          units: 1,
          orderCount: { $size: '$orders' },
        },
      },
      { $sort: { revenue: -1 } },
    ])
    .toArray();

  console.log('Revenue by category:', revenueByCategory);

  // Top SKUs
  const topSkus = await orders
    .aggregate([
      { $match: { status: 'paid' } },
      { $unwind: '$items' },
      {
        $group: {
          _id: '$items.sku',
          units: { $sum: '$items.qty' },
          revenue: {
            $sum: { $multiply: ['$items.qty', '$items.unitPrice'] },
          },
        },
      },
      { $sort: { units: -1 } },
      { $limit: 3 },
      { $project: { _id: 0, sku: '$_id', units: 1, revenue: 1 } },
    ])
    .toArray();

  console.log('Top SKUs:', topSkus);
});
