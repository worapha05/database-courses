import os
from datetime import datetime, timezone

from pymongo import MongoClient, ASCENDING

URI = os.environ.get(
    "MONGO_URI",
    "mongodb://bootcamp:bootcamp@localhost:27017/bootcamp?authSource=admin&replicaSet=rs0&directConnection=true",
)

with MongoClient(URI) as client:
    products = client.bootcamp.products_beginner_py

    products.delete_many({})
    products.create_index([("sku", ASCENDING)], unique=True)

    # CREATE
    products.insert_one(
        {
            "sku": "TSHIRT-01",
            "name": "Classic Tee",
            "price": 390,
            "tags": ["apparel", "cotton"],
            "stock": 25,
            "active": True,
            "createdAt": datetime.now(timezone.utc),
        }
    )

    # READ
    found = products.find_one({"price": {"$gte": 200, "$lte": 400}})
    print("find_one:", found["sku"] if found else None)

    # UPDATE
    products.update_one(
        {"sku": "TSHIRT-01"},
        {"$set": {"price": 420}, "$inc": {"stock": -1}},
    )
    print(
        "after update:",
        products.find_one({"sku": "TSHIRT-01"}, {"_id": 0, "price": 1, "stock": 1}),
    )

    # DELETE
    products.delete_one({"sku": "TSHIRT-01"})

print("done")
