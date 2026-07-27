import json
import os

import redis

r = redis.from_url(
    os.environ.get("REDIS_URL", "redis://localhost:6379"),
    decode_responses=True,
)

# SET + GET พร้อม TTL
r.set(
    "cache:product:TSHIRT-01",
    json.dumps({"name": "Classic Tee", "price": 390}),
    ex=60,
)
print("GET:", json.loads(r.get("cache:product:TSHIRT-01")))

# Atomic counter
r.delete("metrics:pageviews:home")
print("INCR:", r.incr("metrics:pageviews:home"))

# TTL
r.set("session:user:42", "mira-token")
r.expire("session:user:42", 5)
print("TTL:", r.ttl("session:user:42"))

print("done")
