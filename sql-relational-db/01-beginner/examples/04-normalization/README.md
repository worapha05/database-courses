# 04 — Normalization

เดินจากตาราง messy → 1NF → schema 3NF ที่ใช้งานจริง

## คำถามทบทวน

1. `products` ใน cell เดียวผิด 1NF อย่างไร?
2. ทำไม `customer_city` ใน `orders_1nf` ผิด 2NF/3NF?
3. ทำไมต้องเก็บ `unit_price` ใน `norm_order_items` ทั้งที่มีราคาใน `norm_products`?
