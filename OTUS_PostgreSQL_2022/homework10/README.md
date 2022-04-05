# Homework 10

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

## log_min_duration_statement

Change checkpoint_timeout:
```
sed -i 's@#log_lock_waits = off@log_lock_waits = on@' /etc/postgresql/14/main/postgresql.conf
sed -i 's@#deadlock_timeout = 1s@deadlock_timeout = 200ms@' /etc/postgresql/14/main/postgresql.conf
systemctl restart postgresql
```

Populate DB:
```
CREATE DATABASE otus;
\c otus

CREATE TABLE test(
   id SERIAL PRIMARY KEY,
   name VARCHAR NOT NULL,
   number INTEGER DEFAULT 0
);

insert into test (
    name
)
select
    md5(random()::VARCHAR)
from generate_series(1, 10000000);
```

On session 1:
```
otus=# BEGIN;
BEGIN
otus=*# UPDATE test SET number=number+1 WHERE id=1;
UPDATE 1
```

On session 2:
```
otus=# BEGIN;
BEGIN
otus=*# UPDATE test SET number=number+1 WHERE id=1;
UPDATE 1
```

On session 1:
```
otus=*# COMMIT;
```

On session 2:
```
otus=*# COMMIT;
```

Check log:
```
root@postgresql:/home/ubuntu# tail -6 /var/log/postgresql/postgresql-14-main.log
2022-04-05 17:32:45.875 UTC [6314] postgres@otus DETAIL:  Process holding the lock: 6311. Wait queue: 6314.
2022-04-05 17:32:45.875 UTC [6314] postgres@otus CONTEXT:  while updating tuple (9345,89) in relation "test"
2022-04-05 17:32:45.875 UTC [6314] postgres@otus STATEMENT:  UPDATE test SET number=number+1 WHERE id=1;
2022-04-05 17:32:54.521 UTC [6314] postgres@otus LOG:  process 6314 acquired ShareLock on transaction 741 after 9646.116 ms
2022-04-05 17:32:54.521 UTC [6314] postgres@otus CONTEXT:  while updating tuple (9345,89) in relation "test"
2022-04-05 17:32:54.521 UTC [6314] postgres@otus STATEMENT:  UPDATE test SET number=number+1 WHERE id=1;
```

## 3 sessions and pg_locks

On session 1:
```
otus=# SELECT pg_backend_pid();
 pg_backend_pid 
----------------
           6314
(1 row)
```

On session 2:
```
otus=# SELECT pg_backend_pid();
 pg_backend_pid 
----------------
           6311
(1 row)
```

On session 3:
```
otus=# SELECT pg_backend_pid();
 pg_backend_pid 
----------------
           6324
(1 row)
```

On session 1:
```
otus=# SELECT locktype, relation::REGCLASS, virtualxid AS virtxid, transactionid AS xid, mode, granted
otus-# FROM pg_locks WHERE pid = 6314;
  locktype  | relation | virtxid | xid |      mode       | granted 
------------+----------+---------+-----+-----------------+---------
 relation   | pg_locks |         |     | AccessShareLock | t
 virtualxid |          | 5/4     |     | ExclusiveLock   | t
(2 rows)
```

locktype:
* relation	Waiting to acquire a lock on a relation.
* virtualxid	Waiting to acquire a virtual transaction ID lock.

On session 1:
```
otus=# BEGIN;
BEGIN
otus=*# UPDATE test SET number=number+1 WHERE id=1;
UPDATE 1
```

On session 2:
```
otus=# BEGIN;
BEGIN
otus=*# UPDATE test SET number=number+1 WHERE id=1;
UPDATE 1
```

On session 3:
```
otus=# BEGIN;
BEGIN
otus=*# UPDATE test SET number=number+1 WHERE id=1;
UPDATE 1
```

Now check locks:
```
otus=*# SELECT locktype, relation::REGCLASS, virtualxid AS virtxid, transactionid AS xid, mode, granted FROM pg_locks WHERE pid = 6314;
   locktype    | relation  | virtxid | xid |       mode       | granted 
---------------+-----------+---------+-----+------------------+---------
 relation      | pg_locks  |         |     | AccessShareLock  | t
 relation      | test_pkey |         |     | RowExclusiveLock | t
 relation      | test      |         |     | RowExclusiveLock | t
 virtualxid    |           | 5/5     |     | ExclusiveLock    | t
 transactionid |           |         | 743 | ExclusiveLock    | t
(5 rows)

otus=*# SELECT locktype, relation::REGCLASS, virtualxid AS virtxid, transactionid AS xid, mode, granted FROM pg_locks WHERE pid = 6311;
   locktype    | relation  | virtxid | xid |       mode       | granted 
---------------+-----------+---------+-----+------------------+---------
 relation      | test_pkey |         |     | RowExclusiveLock | t
 relation      | test      |         |     | RowExclusiveLock | t
 virtualxid    |           | 4/6     |     | ExclusiveLock    | t
 tuple         | test      |         |     | ExclusiveLock    | t
 transactionid |           |         | 744 | ExclusiveLock    | t
 transactionid |           |         | 743 | ShareLock        | f
(6 rows)

otus=*# SELECT locktype, relation::REGCLASS, virtualxid AS virtxid, transactionid AS xid, mode, granted FROM pg_locks WHERE pid = 6324;
   locktype    | relation  | virtxid | xid |       mode       | granted 
---------------+-----------+---------+-----+------------------+---------
 relation      | test_pkey |         |     | RowExclusiveLock | t
 relation      | test      |         |     | RowExclusiveLock | t
 virtualxid    |           | 6/3     |     | ExclusiveLock    | t
 tuple         | test      |         |     | ExclusiveLock    | f
 transactionid |           |         | 745 | ExclusiveLock    | t
(5 rows)
```

New locktype:
* tuple	Waiting to acquire a lock on a tuple.
* transactionid	Waiting for a transaction to finish.

## 3 session and deadlock

It possible when session 2 wait session 1, session 3 wait session 2 and session 1 wait session 3.

### Step One

On session 1:
```
otus=# BEGIN;
BEGIN
otus=*# UPDATE test SET number=number+1 WHERE id=1;
UPDATE 1
```

On session 2:
```
otus=# BEGIN;
BEGIN
otus=*# UPDATE test SET number=number+2 WHERE id=2;
UPDATE 1
otus=*# UPDATE test SET number=number+3 WHERE id=1;
```

On session 3:
```
otus=# BEGIN; 
BEGIN
otus=*# UPDATE test SET number=number+3 WHERE id=3;
UPDATE 1
otus=*# UPDATE test SET number=number+1 WHERE id=2;
```

### Step Two
On session 1:
```
otus=*# UPDATE test SET number=number+3 WHERE id=3;
ERROR:  deadlock detected
DETAIL:  Process 6314 waits for ShareLock on transaction 751; blocked by process 6324.
Process 6324 waits for ShareLock on transaction 750; blocked by process 6311.
Process 6311 waits for ShareLock on transaction 749; blocked by process 6314.
HINT:  See server log for query details.
CONTEXT:  while updating tuple (9345,99) in relation "test"
```

And commit:
```
otus=!# COMMIT;
ROLLBACK
```

And check logs:
```
2022-04-05 18:03:17.146 UTC [6311] postgres@otus LOG:  process 6311 still waiting for ShareLock on transaction 749 after 1000.157 ms
2022-04-05 18:03:17.146 UTC [6311] postgres@otus DETAIL:  Process holding the lock: 6314. Wait queue: 6311.
2022-04-05 18:03:17.146 UTC [6311] postgres@otus CONTEXT:  while updating tuple (9345,98) in relation "test"
2022-04-05 18:03:17.146 UTC [6311] postgres@otus STATEMENT:  UPDATE test SET number=number+3 WHERE id=1;
2022-04-05 18:03:30.049 UTC [6324] postgres@otus LOG:  process 6324 still waiting for ShareLock on transaction 750 after 1000.274 ms
2022-04-05 18:03:30.049 UTC [6324] postgres@otus DETAIL:  Process holding the lock: 6311. Wait queue: 6324.
2022-04-05 18:03:30.049 UTC [6324] postgres@otus CONTEXT:  while updating tuple (9345,97) in relation "test"
2022-04-05 18:03:30.049 UTC [6324] postgres@otus STATEMENT:  UPDATE test SET number=number+1 WHERE id=2;
2022-04-05 18:04:39.155 UTC [6314] postgres@otus LOG:  process 6314 detected deadlock while waiting for ShareLock on transaction 751 after 1000.191 ms
2022-04-05 18:04:39.155 UTC [6314] postgres@otus DETAIL:  Process holding the lock: 6324. Wait queue: .
2022-04-05 18:04:39.155 UTC [6314] postgres@otus CONTEXT:  while updating tuple (9345,99) in relation "test"
2022-04-05 18:04:39.155 UTC [6314] postgres@otus STATEMENT:  UPDATE test SET number=number+3 WHERE id=3;
2022-04-05 18:04:39.156 UTC [6314] postgres@otus ERROR:  deadlock detected
2022-04-05 18:04:39.156 UTC [6314] postgres@otus DETAIL:  Process 6314 waits for ShareLock on transaction 751; blocked by process 6324.
        Process 6324 waits for ShareLock on transaction 750; blocked by process 6311.
        Process 6311 waits for ShareLock on transaction 749; blocked by process 6314.
        Process 6314: UPDATE test SET number=number+3 WHERE id=3;
        Process 6324: UPDATE test SET number=number+1 WHERE id=2;
        Process 6311: UPDATE test SET number=number+3 WHERE id=1;
2022-04-05 18:04:39.156 UTC [6314] postgres@otus HINT:  See server log for query details.
2022-04-05 18:04:39.156 UTC [6314] postgres@otus CONTEXT:  while updating tuple (9345,99) in relation "test"
2022-04-05 18:04:39.156 UTC [6314] postgres@otus STATEMENT:  UPDATE test SET number=number+3 WHERE id=3;
2022-04-05 18:04:39.156 UTC [6311] postgres@otus LOG:  process 6311 acquired ShareLock on transaction 749 after 83010.642 ms
2022-04-05 18:04:39.156 UTC [6311] postgres@otus CONTEXT:  while updating tuple (9345,98) in relation "test"
2022-04-05 18:04:39.156 UTC [6311] postgres@otus STATEMENT:  UPDATE test SET number=number+3 WHERE id=1;
```

It's easy to find that there was a circular blocking of three transactions:
```
Process 6314 waits for ShareLock on transaction 751; blocked by process 6324.
Process 6324 waits for ShareLock on transaction 750; blocked by process 6311.
Process 6311 waits for ShareLock on transaction 749; blocked by process 6314.
```

## Deadlock in UPDATE without WHERE and SELECT

Create and populate a new table:
```
CREATE TABLE test2(
   id INTEGER,
   name VARCHAR,
   eman VARCHAR
);

INSERT into test2 (id) VALUES (0),(1),(2),(3),(4),(5),(6),(7);
INSERT into test2 (id) VALUES (0),(1),(2),(3),(4),(5),(6),(7);
```

On session 1:
```
otus=# BEGIN;
BEGIN
otus=*# UPDATE test2 SET name=id RETURNING *,pg_sleep(5),pg_advisory_lock(id);
```

Then we wait 10 seconds and run on session 2:
```
otus=# BEGIN;
BEGIN
otus=*# VALUES(pg_advisory_lock(5));
otus=*# UPDATE test2 SET name=id RETURNING *,pg_sleep(5),pg_advisory_lock(5+id);
```

And waiting on session 1:
```
ERROR:  deadlock detected
DETAIL:  Process 6314 waits for ExclusiveLock on advisory lock [16384,0,5,1]; blocked by process 7190.
Process 7190 waits for ShareLock on transaction 820; blocked by process 6314.
HINT:  See server log for query details.
```
