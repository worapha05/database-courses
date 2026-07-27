// ── Connections ──────────────────────────────────────────────────────────────

import { MongoClient } from 'mongodb'
import Redis from 'ioredis'

export const MONGO_URI =
  process.env.MONGO_URI ??
  'mongodb://bootcamp:bootcamp@localhost:27017/bootcamp?authSource=admin&replicaSet=rs0&directConnection=true'

export const REDIS_URL =
  process.env.REDIS_URL ?? 'redis://localhost:6379'

export async function withMongo(dbName, fn) {
  const client = new MongoClient(MONGO_URI)
  await client.connect()
  try {
    const db = client.db(dbName ?? 'bootcamp')
    return await fn(db, client)
  } finally {
    await client.close()
  }
}

export function createRedis() {
  return new Redis(REDIS_URL, {
    maxRetriesPerRequest: 3,
    lazyConnect: false
  })
}

export async function withRedis(fn) {
  const redis = createRedis()
  try {
    return await fn(redis)
  } finally {
    redis.disconnect()
  }
}
