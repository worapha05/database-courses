-- Approximate shape of Liquibase tracking tables (tool-managed).

CREATE TABLE IF NOT EXISTS databasechangelog (id VARCHAR(255) NOT NULL,
                                                              author VARCHAR(255) NOT NULL,
                                                                                  filename VARCHAR(255) NOT NULL,
                                                                                                        dateexecuted TIMESTAMPTZ NOT NULL,
                                                                                                                                 orderexecuted INTEGER NOT NULL,
                                                                                                                                                       exectype VARCHAR(10) NOT NULL,
                                                                                                                                                                            md5sum VARCHAR(35),
                                                                                                                                                                                   description VARCHAR(255),
                                                                                                                                                                                               comments VARCHAR(255),
                                                                                                                                                                                                        tag VARCHAR(255),
                                                                                                                                                                                                            liquibase VARCHAR(20),
                                                                                                                                                                                                                      contexts VARCHAR(255),
                                                                                                                                                                                                                               labels VARCHAR(255),
                                                                                                                                                                                                                                      deployment_id VARCHAR(10));


CREATE TABLE IF NOT EXISTS databasechangeloglock (id INTEGER PRIMARY KEY,
                                                             locked BOOLEAN NOT NULL,
                                                                            lockgranted TIMESTAMPTZ,
                                                                            lockedby VARCHAR(255));
