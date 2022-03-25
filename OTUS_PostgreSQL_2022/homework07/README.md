# Homework 07

Apple Terraform configuration:
```
terraform apply
```

Generate Ansible inventory:
```
echo -e "[dbservers]\n$(terraform output nat_ip|tr -d \")" > hosts
```

Install PostgreSQL:
```
ansible-playbook -i hosts main.yml -u ubuntu
```

Open SSH sessions:
```
ssh ubuntu@$(terraform output nat_ip|tr -d \")
```

Do steps:
```
postgres=# \conninfo 
You are connected to database "postgres" as user "postgres" via socket in "/var/run/postgresql" at port "5432".
postgres=# CREATE DATABASE testdb;
CREATE DATABASE
postgres=# \c testdb
You are now connected to database "testdb" as user "postgres".
testdb=# CREATE SCHEMA testnm;
CREATE SCHEMA
testdb=# CREATE TABLE t1 (c1 integer);
CREATE TABLE
testdb=# INSERT INTO t1 VALUES(1);
INSERT 0 1
testdb=# CREATE ROLE readonly;
CREATE ROLE
testdb=# GRANT CONNECT ON DATABASE testdb TO readonly;
GRANT
testdb=# GRANT USAGE ON SCHEMA testnm TO readonly;
GRANT
testdb=# GRANT SELECT ON ALL TABLES IN SCHEMA testnm TO readonly;
GRANT
testdb=# CREATE USER testread PASSWORD 'test123';
CREATE ROLE
testdb=# GRANT readonly TO testread;
GRANT ROLE

postgres@postgresql:~$ psql -U testread -h 127.0.0.1 testdb
Password for user testread: 
psql (14.2 (Ubuntu 14.2-1.pgdg20.04+1))
SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, bits: 256, compression: off)
Type "help" for help.
testdb=> SELECT * FROM t1;
ERROR:  permission denied for table t1
```

Because I granted only testnm namespaces permissions and t2 is in public schema:
```
because for permission on public select
testdb=> \d
        List of relations
 Schema | Name | Type  |  Owner   
--------+------+-------+----------
 public | t1   | table | postgres
(1 row)
```

This happened because default schema is public:
```
testdb=# SHOW search_path;
   search_path   
-----------------
 "$user", public
(1 row)
```

First turn to fix:
```
testdb=# DROP TABLE t1;
DROP TABLE
testdb=# CREATE TABLE testnm.t1 (c1 integer);
CREATE TABLE
testdb=# INSERT INTO testnm.t1 VALUES(1);
INSERT 0 1
testdb=> SELECT * FROM testnm.t1 ;
ERROR:  permission denied for table t1
```

Because GRANT run before table creation. Fix this:
```
testdb=# GRANT SELECT ON ALL TABLES IN SCHEMA testnm TO readonly;
GRANT
testdb=# ALTER DEFAULT PRIVILEGES IN SCHEMA testnm GRANT SELECT ON TABLES TO readonly ;
ALTER DEFAULT PRIVILEGES

testdb=> SELECT * FROM testnm.t1 ;
 c1 
----
  1
(1 row)
```

Next step:
```
testdb=> create table t2(c1 integer); insert into t2 values (2);
CREATE TABLE
INSERT 0 1
testdb=> \d
        List of relations
 Schema | Name | Type  |  Owner   
--------+------+-------+----------
 public | t2   | table | testread
(1 row)
```

This is possible because schema public have `C` permission for PUBLIC privilege:
```
tdb=> select * from pg_namespace ;
  oid  |      nspname       | nspowner |                   nspacl                   
-------+--------------------+----------+--------------------------------------------
    99 | pg_toast           |       10 | 
    11 | pg_catalog         |       10 | {postgres=UC/postgres,=U/postgres}
  2200 | public             |       10 | {postgres=UC/postgres,=UC/postgres}
```

Fix this and test:
```
testdb=# REVOKE CREATE ON SCHEMA public FROM public; 
REVOKE
testdb=# ALTER TABLE t2 OWNER TO postgres;
ALTER TABLE


testdb=>  create table t3(c1 integer); insert into t2 values (2);
ERROR:  permission denied for schema public
LINE 1: create table t3(c1 integer);
                     ^
ERROR:  permission denied for table t2
```
