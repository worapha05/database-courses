const relational = {
  tables: ['customers', 'products', 'orders', 'order_items'],
  getOrder: 'SELECT o.*, c.email, oi.*, p.name FROM orders o JOIN ...',
  note: 'ความสัมพันธ์ชัด, JOIN มีค่าใช้จ่าย, schema ตายตัว',
};

const mongoDocument = {
  collection: 'orders',
  document: {
    _id: 'oid...',
    orderNo: 'ORD-1001',
    customer: { id: 'c1', email: 'mira@ex.com', name: 'Mira' },
    items: [
      { sku: 'TSHIRT-01', name: 'Classic Tee', qty: 2, unitPrice: 390 },
      { sku: 'HAT-02', name: 'Cap', qty: 1, unitPrice: 250 },
    ],
    total: 1030,
    status: 'paid',
    createdAt: '2026-07-18T00:00:00.000Z',
  },
  note: 'อ่านออเดอร์ครั้งเดียวจบ — ไม่ต้อง JOIN; snapshot ราคาตอนสั่งอยู่ใน items',
};

const redisKeys = {
  'product:TSHIRT-01:stock': '42',
  'session:mira': { cartId: 'cart9', role: 'customer' },
  'cache:product:TSHIRT-01': '{"name":"Classic Tee","price":390}',
  note: 'เร็ว, มี TTL; ไม่เก็บประวัติออเดอร์หลักที่นี่',
};

console.log('=== Relational mindset ===');
console.log(relational);

console.log('\n=== MongoDB document mindset ===');
console.log(JSON.stringify(mongoDocument, null, 2));

console.log('\n=== Redis key-value mindset ===');
console.log(redisKeys);

console.log(
  '\nสรุป: MongoDB = source of truth สำหรับออเดอร์; Redis = cache/session/stock hot path',
);
