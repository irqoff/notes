# Homework 02

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

Open SSH and tmux sessions:
```
ssh ubuntu@$(terraform output nat_ip|tr -d \")
tmux
```

Open PostgreSQL connections:
```
sudo -u postgres psql
\set AUTOCOMMIT off
sudo -u postgres psql
\set AUTOCOMMIT off
```

Current transaction isolation level:
```
postgres=# show transaction isolation level;
 transaction_isolation
-----------------------
 read committed
(1 row)
```

READ COMMITTED exercise:
```
connection 1:
postgres=*# create table persons(id serial, first_name text, second_name text); insert into persons(first_name, second_name) values('ivan', 'ivanov'); insert into persons(first_name, second_name) values('petr', 'petrov'); commit;
CREATE TABLE
INSERT 0 1
INSERT 0 1
COMMIT
postgres=# BEGIN;
BEGIN
postgres=*# 
postgres=*# insert into persons(first_name, second_name) values('sergey', 'sergeev');
INSERT 0 1
postgres=*# COMMIT;
COMMIT

connection 2:
postgres=# BEGIN;
BEGIN
postgres=*# select * from persons;
 id | first_name | second_name 
----+------------+-------------
  1 | ivan       | ivanov
  2 | petr       | petrov
(2 rows)

postgres=*# select * from persons;
 id | first_name | second_name 
----+------------+-------------
  1 | ivan       | ivanov
  2 | petr       | petrov
  3 | sergey     | sergeev
(3 rows)

postgres=*# COMMIT;
COMMIT
```

When a transaction uses *read committed* isolation level, a SELECT query (without a FOR UPDATE/SHARE clause) sees only data committed before the query began and can see different data, if other transactions commit changes.


REPEATABLE READ exercise:
```
connection 1:
postgres=# BEGIN ISOLATION LEVEL REPEATABLE READ;
BEGIN
postgres=*# insert into persons(first_name, second_name) values('sveta', 'svetova');
INSERT 0 1
postgres=*# COMMIT;
COMMIT

connection 2:
postgres=# BEGIN ISOLATION LEVEL REPEATABLE READ;
BEGIN
postgres=*# select * from persons
postgres-*# ;
 id | first_name | second_name 
----+------------+-------------
  1 | ivan       | ivanov
  2 | petr       | petrov
  3 | sergey     | sergeev
(3 rows)

postgres=*# select * from persons;
 id | first_name | second_name 
----+------------+-------------
  1 | ivan       | ivanov
  2 | petr       | petrov
  3 | sergey     | sergeev
(3 rows)

postgres=*# COMMIT;
COMMIT
postgres=# select * from persons;
 id | first_name | second_name 
----+------------+-------------
  1 | ivan       | ivanov
  2 | petr       | petrov
  3 | sergey     | sergeev
  4 | sveta      | svetova
(4 rows)
```

The *repeatable read* isolation level only sees data committed before the transaction began; it never sees either uncommitted data or changes committed during transaction execution by concurrent transactions.
