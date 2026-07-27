# Lab Solution — FlashMart (Beginner)

## รันเฉลย

```bash
docker compose -f .infra/docker-compose.yml up -d
npm install
node 01-beginner/lab/solution/flashmart.js
```

Script จะ:

1. seed products + สร้าง order
2. ทดสอบ Redis session / cache
3. รัน `getProduct` (cache miss แล้ว hit)
4. update สต็อกแล้ว invalidate cache
