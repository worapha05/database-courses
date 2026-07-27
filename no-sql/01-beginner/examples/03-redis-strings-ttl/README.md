# 03 — Redis Strings & TTL

ฝึก `SET` / `GET` / `DEL` / `INCR` และ `EXPIRE` / `TTL`

## รัน

```bash
node 01-beginner/examples/03-redis-strings-ttl/strings.js
python 01-beginner/examples/03-redis-strings-ttl/strings.py
```

## Production commands ที่ควรรู้จัก

```bash
redis-cli INFO memory
redis-cli --bigkeys
redis-cli TTL session:42
redis-cli MEMORY USAGE cache:product:TSHIRT-01
```
