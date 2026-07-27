db = db.getSiblingDB('bootcamp')

db.createUser({
  user: 'bootcamp',
  pwd: 'bootcamp',
  roles: [{ role: 'readWrite', db: 'bootcamp' }]
})

db.createCollection('_bootcamp_ready')
