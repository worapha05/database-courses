const guide = {
  mongodb: {
    replicaSet: {
      problem: 'high availability + failover + change streams',
      notSolve: 'write throughput แนวนอน (ต้อง shard)',
      when: 'production ทุกครั้ง — อย่างน้อย 3 โหนด',
    },
    sharding: {
      problem: 'data size / write scale เกินเครื่องเดียว',
      risk: 'shard key ผิด → hotspot หรือ scatter-gather',
      when: 'ข้อมูลใหญ่และ query pattern ชัดเจน',
    },
  },
  redis: {
    sentinel: {
      problem: 'HA ของ primary/replica topology แบบ classic',
      client: 'ต้องรองรับ sentinel discovery',
    },
    cluster: {
      problem: 'scale memory + throughput แนวนอน',
      note: 'multi-key ต้องอยู่ slot เดียวกัน — ใช้ hash tag {entityId}',
    },
  },
  connectionExamples: {
    mongoRS:
      'mongodb://bootcamp:bootcamp@m1:27017,m2:27017,m3:27017/bootcamp?replicaSet=rs0&authSource=admin',
    redisSentinel: {
      sentinels: ['sent1:26379', 'sent2:26379', 'sent3:26379'],
      name: 'mymaster',
    },
    redisClusterHashTag: '{user:42}:session และ {user:42}:cart อยู่ slot เดียวกัน',
  },
};

console.log(JSON.stringify(guide, null, 2));
console.log('\nกฎทอง: HA ≠ Backup — ต้องมี snapshot/PITR แยกต่างหาก');
