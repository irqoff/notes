# Homework 14

Apple Terraform configuration:
```
terraform apply
```

Generate Ansible inventory:
```
terraform output postgresql_ip | grep , | awk -F \" 'BEGIN {print "[dbservers]"; s=0} {print "db0" s " ansible_host=" $2; s += 1} > hosts
```

Install PostgreSQL:
```
ansible-playbook -i hosts main.yml -u ubuntu
```

## Logical replication

Login on db0:
```
ssh ubuntu@$(grep db00 hosts|cut -f 2 -d =)
```

Configure PostgreSQL:
```
echo "host    all     replication             0.0.0.0/0               scram-sha-256" >> /etc/postgresql/14/main/pg_hba.conf
sed -i 's@#wal_level = replica@wal_level = logical@' /etc/postgresql/14/main/postgresql.conf
sed -i "s@#listen_addresses = 'localhost'@listen_addresses = '*'@" /etc/postgresql/14/main/postgresql.conf
systemctl restart postgresql
```

Create test database and tables:
```
CREATE DATABASE test;
\c test

CREATE TABLE test0(
   id SERIAL PRIMARY KEY,
   name VARCHAR NOT NULL
);

CREATE TABLE test1(
   id SERIAL PRIMARY KEY,
   name VARCHAR NOT NULL
);

insert into test0 (
    name
)
select
    md5(random()::VARCHAR)
from generate_series(1, 100);

otus=# select count(*) from test0;
  count 
---------
 100
(1 row)
```

Create publication and role:
```
test=# CREATE PUBLICATION test0 FOR TABLE test0;
CREATE PUBLICATION
test=# CREATE PUBLICATION test0_2 FOR TABLE test0;
CREATE PUBLICATION
test=# CREATE USER replication WITH PASSWORD 'replication' REPLICATION;
CREATE ROLE
test=# GRANT SELECT ON TABLE test0 TO replication;
GRANT
```

Login db01:
```
ssh ubuntu@$(grep db01 hosts|cut -f 2 -d =)
```

Configure PostgreSQL:
```
echo "host    all     replication             0.0.0.0/0               scram-sha-256" >> /etc/postgresql/14/main/pg_hba.conf
sed -i 's@#wal_level = replica@wal_level = logical@' /etc/postgresql/14/main/postgresql.conf
sed -i "s@#listen_addresses = 'localhost'@listen_addresses = '*'@" /etc/postgresql/14/main/postgresql.conf
systemctl restart postgresql
```

Create test database and tables:
```
CREATE DATABASE test;
\c test

CREATE TABLE test0(
   id SERIAL PRIMARY KEY,
   name VARCHAR NOT NULL
);

CREATE TABLE test1(
   id SERIAL PRIMARY KEY,
   name VARCHAR NOT NULL
);

insert into test1 (
    name
)
select
    md5(random()::VARCHAR)
from generate_series(1, 100);

otus=# select count(*) from test1;
  count
---------
 100
(1 row)
```

Create publication and role:
```
test=# CREATE PUBLICATION test1 FOR TABLE test0;
CREATE PUBLICATION
test=# CREATE PUBLICATION test1_2 FOR TABLE test0;
CREATE PUBLICATION
test=# CREATE USER replication WITH PASSWORD 'replication' REPLICATION;
CREATE ROLE
test=# GRANT SELECT ON TABLE test1 TO replication;
GRANT
```

Create subscription on db00:
```
CREATE SUBSCRIPTION test1 CONNECTION 'dbname=test host=10.166.0.17 user=replication password=replication' PUBLICATION test1;
```
Create subscription on db01:
```
CREATE SUBSCRIPTION test0 CONNECTION 'dbname=test host=10.166.0.19 user=replication password=replication' PUBLICATION test0;
```

Check db00 for example:
```
test=# \dRp+
                             Publication test0
  Owner   | All tables | Inserts | Updates | Deletes | Truncates | Via root 
----------+------------+---------+---------+---------+-----------+----------
 postgres | f          | t       | t       | t       | t         | f
Tables:
    "public.test0"

                            Publication test0_2
  Owner   | All tables | Inserts | Updates | Deletes | Truncates | Via root 
----------+------------+---------+---------+---------+-----------+----------
 postgres | f          | t       | t       | t       | t         | f
Tables:
    "public.test0"

test=# \dRs+
                                                                  List of subscriptions
 Name  |  Owner   | Enabled | Publication | Binary | Streaming | Synchronous commit |                              Conninfo                              
-------+----------+---------+-------------+--------+-----------+--------------------+--------------------------------------------------------------------
 mysub | postgres | t       | {test1}     | f      | f         | off                | dbname=test host=10.166.0.17 user=replication password=replication
(1 row)

test=# select count(*) from test0;
 count 
-------
   100
(1 row)

test=# select count(*) from test1;
 count 
-------
   100
(1 row)
```

## Host for read and backup

Login on db02:
```
ssh ubuntu@$(grep db02 hosts|cut -f 2 -d =)
```

Configure it:
```
echo "host    all     replication             0.0.0.0/0               scram-sha-256" >> /etc/postgresql/14/main/pg_hba.conf
echo "host    replication replication         0.0.0.0/0               scram-sha-256" >> /etc/postgresql/14/main/pg_hba.conf
sed -i 's@#wal_level = replica@wal_level = logical@' /etc/postgresql/14/main/postgresql.conf
sed -i "s@#listen_addresses = 'localhost'@listen_addresses = '*'@" /etc/postgresql/14/main/postgresql.conf
systemctl restart postgresql
```

Create the database and tables:
```
CREATE DATABASE test;
\c test

CREATE TABLE test0(
   id SERIAL PRIMARY KEY,
   name VARCHAR NOT NULL
);

CREATE TABLE test1(
   id SERIAL PRIMARY KEY,
   name VARCHAR NOT NULL
);
```

Create subscription:
```
CREATE SUBSCRIPTION test1_2 CONNECTION 'dbname=test host=10.166.0.17 user=replication password=replication' PUBLICATION test1_2;
CREATE SUBSCRIPTION test0_2  CONNECTION 'dbname=test host=10.166.0.19 user=replication password=replication' PUBLICATION test0_2;

test=# \dRs+
                                                                   List of subscriptions
  Name   |  Owner   | Enabled | Publication | Binary | Streaming | Synchronous commit |                              Conninfo                              
---------+----------+---------+-------------+--------+-----------+--------------------+--------------------------------------------------------------------
 test0_2 | postgres | t       | {test0_2}   | f      | f         | off                | dbname=test host=10.166.0.19 user=replication password=replication
 test1_2 | postgres | t       | {test1_2}   | f      | f         | off                | dbname=test host=10.166.0.17 user=replication password=replication
(2 rows)

test=# select count(*) from test1;
 count 
-------
   100
(1 row)

test=# select count(*) from test0;
 count 
-------
   100
(1 row)
```

## Caveats

We should set sequence values if we want to promote logical replication host:
```
test=# SELECT setval('test0_id_seq', 101, false);
 setval 
--------
    101
(1 row)

test=# SELECT setval('test1_id_seq', 101, false);
 setval 
--------
    101
(1 row)
```

## Physical replication

On db02:
```
test=# CREATE USER replication WITH PASSWORD 'replication' REPLICATION;
CREATE ROLE
```

Login on db03:
```
ssh ubuntu@$(grep db03 hosts|cut -f 2 -d =)
```

Configure replication:
```
systemctl stop postgresql
su - postgres
rm -rf 14/main
pg_basebackup -h 10.166.0.16 -R -U replication -D 14/main
systemctl start postgresql
```

And check on db02:
```
test=# select pg_current_wal_lsn();
 pg_current_wal_lsn 
--------------------
 0/3000148
(1 row)

test=# select * from  pg_stat_replication \gx
-[ RECORD 1 ]----+------------------------------
pid              | 6770
usesysid         | 16414
usename          | replication
application_name | 14/main
client_addr      | 10.166.0.18
client_hostname  | 
client_port      | 60404
backend_start    | 2022-04-20 15:29:49.162894+00
backend_xmin     | 
state            | streaming
sent_lsn         | 0/3000148
write_lsn        | 0/3000148
flush_lsn        | 0/3000148
replay_lsn       | 0/3000148
write_lag        | 
flush_lag        | 
replay_lag       | 
sync_priority    | 0
sync_state       | async
reply_time       | 2022-04-20 15:44:29.889047+00
```


Destroy the VM:
```
terraform destroy
```
