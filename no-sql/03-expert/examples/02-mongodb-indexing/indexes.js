import { withMongo } from '../../../.infra/lib/connections.js';

await withMongo('bootcamp', async db => {
  const orders = db.collection('idx_orders');
  await orders.deleteMany({});
  await orders.dropIndexes().catch(() => {});

  const docs = [];
  for (let i = 0; i < 2000; i++) {
    docs.push({
      orderNo: `ORD-${i}`,
      status: i % 5 === 0 ? 'cancelled' : 'paid',
      total: 100 + (i % 50) * 10,
      createdAt: new Date(Date.UTC(2026, 6, 1 + (i % 28))),
      customerEmail: `user${i % 100}@ex.com`,
      note: i % 7 === 0 ? 'priority rush shipping' : 'standard delivery',
      location: {
        type: 'Point',
        coordinates: [100.5 + (i % 50) * 0.01, 13.7 + (i % 40) * 0.01],
      },
    });
  }
  await orders.insertMany(docs);

  async function showExplain(label, cursor) {
    const stats = await cursor.explain('executionStats');
    const es = stats.executionStats;
    const stage = es.executionStages?.stage ?? es.executionStages?.inputStage?.stage;
    console.log(
      `\n[${label}] stage=${stage} examined=${es.totalDocsExamined} returned=${es.nReturned} ms=${es.executionTimeMillis}`,
    );
  }

  // Before index — likely COLLSCAN
  await showExplain(
    'before index',
    orders
      .find({
        status: 'paid',
        createdAt: { $gte: new Date('2026-07-10') },
      })
      .sort({ createdAt: -1 }),
  );

  await orders.createIndex({ customerEmail: 1 });
  await orders.createIndex({ status: 1, createdAt: -1, total: 1 });
  await orders.createIndex({ note: 'text' });
  await orders.createIndex({ location: '2dsphere' });

  // After index — should be IXSCAN
  await showExplain(
    'after compound index',
    orders
      .find({
        status: 'paid',
        createdAt: { $gte: new Date('2026-07-10') },
      })
      .sort({ createdAt: -1 }),
  );

  // Text search
  const textHits = await orders
    .find(
      { $text: { $search: 'priority rush' } },
      {
        projection: {
          score: { $meta: 'textScore' },
          orderNo: 1,
          note: 1,
        },
      },
    )
    .sort({ score: { $meta: 'textScore' } })
    .limit(3)
    .toArray();
  console.log('\ntext search top:', textHits);

  // Geospatial search
  const near = await orders
    .find({
      location: {
        $near: {
          $geometry: {
            type: 'Point',
            coordinates: [100.52, 13.72],
          },
          $maxDistance: 3000,
        },
      },
    })
    .project({ orderNo: 1, location: 1, _id: 0 })
    .limit(3)
    .toArray();
  console.log('geo near:', near);

  console.log('\nindexes:', await orders.indexes());
});
