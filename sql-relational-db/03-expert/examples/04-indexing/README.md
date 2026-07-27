# 04 — Strategic Indexing

| เทคนิค        | PostgreSQL                  | MySQL                        |
| ------------- | --------------------------- | ---------------------------- |
| Partial index | รองรับ                      | ใช้ composite + filter แทน   |
| Covering      | `INCLUDE` / index-only scan | secondary index ครบ column   |
| Full-text     | `tsvector` + GIN            | `FULLTEXT` + `MATCH…AGAINST` |
