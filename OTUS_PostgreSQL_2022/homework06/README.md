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

Check cluster information:
```
ubuntu@postgresql:~$ sudo -u postgres pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
14  main    5432 online postgres /var/lib/postgresql/14/main /var/log/postgresql/postgresql-14-main.log
```

Fill a table:
```
ubuntu@postgresql:~$ sudo -u postgres psql
psql (14.2 (Ubuntu 14.2-1.pgdg20.04+1))
Type "help" for help.

postgres=# CREATE DATABASE test;
CREATE DATABASE
postgres=# \c test
You are now connected to database "test" as user "postgres".
test=# create table test(c1 text);
CREATE TABLE
test=# insert into test values('1');
INSERT 0 1
```

Stop cluster:
```
sudo systemctl stop postgresql@14-main
```

Move and start:
```
sudo mv /var/lib/postgresql/14/main/* /mnt/data
root@postgresql:/home/ubuntu# systemctl start postgresql@14-main
Job for postgresql@14-main.service failed because the service did not take the steps required by its unit configuration.
See "systemctl status postgresql@14-main.service" and "journalctl -xe" for details.
root@postgresql:/home/ubuntu# journalctl -u postgresql@14-main
-- Logs begin at Mon 2022-03-21 20:11:56 UTC, end at Mon 2022-03-21 20:37:01 UTC. --
Mar 21 20:13:47 postgresql systemd[1]: Starting PostgreSQL Cluster 14-main...
Mar 21 20:13:49 postgresql systemd[1]: Started PostgreSQL Cluster 14-main.
Mar 21 20:34:14 postgresql postgresql@14-main[6677]: Cluster is not running.
Mar 21 20:34:14 postgresql systemd[1]: postgresql@14-main.service: Control process exited, code=exited, status=2/INVALIDARGUMENT
Mar 21 20:34:14 postgresql systemd[1]: postgresql@14-main.service: Failed with result 'exit-code'.
Mar 21 20:37:01 postgresql systemd[1]: Starting PostgreSQL Cluster 14-main...
Mar 21 20:37:01 postgresql postgresql@14-main[6703]: Error: /usr/lib/postgresql/14/bin/pg_ctl /usr/lib/postgresql/14/bin/pg_ctl start -D /var/lib/postgresql/14/main -l /var/log/postgresql/postgresql-14-main.log>
Mar 21 20:37:01 postgresql postgresql@14-main[6703]: pg_ctl: directory "/var/lib/postgresql/14/main" is not a database cluster directory
Mar 21 20:37:01 postgresql systemd[1]: postgresql@14-main.service: Can't open PID file /run/postgresql/14-main.pid (yet?) after start: Operation not permitted
Mar 21 20:37:01 postgresql systemd[1]: postgresql@14-main.service: Failed with result 'protocol'.
Mar 21 20:37:01 postgresql systemd[1]: Failed to start PostgreSQL Cluster 14-main.
```

Didn't start because data directory is empty.

Change data_directory:
```
sed -i "s@data_directory = .*@data_directory = '/mnt/data'@" /etc/postgresql/14/main/postgresql.conf
systemctl start postgresql@14-main
```

And test:
```
ubuntu@postgresql:~$ sudo -u postgres psql
psql (14.2 (Ubuntu 14.2-1.pgdg20.04+1))
Type "help" for help.

postgres=# \c test
You are now connected to database "test" as user "postgres".
test=# select * from test;
 c1 
----
 1
(1 row)

test=# \q
```

## Additional task

Apply new configuration:
```
cp main.ft main.tf
terraform apply
```

On old host:
```
root@postgresql:/home/ubuntu#  ls /mnt/data/
ls: reading directory '/mnt/data/': Input/output error
```

Generate Ansible inventory:
```
echo -e "[dbservers]\n$(terraform output nat2_ip|tr -d \")" > hosts
```

Run Ansible:
```
ansible-playbook -i hosts main_additional.yml -u ubuntu
```

And check test table:
```
ubuntu@postgresql2:~$ sudo -u postgres psql
psql (14.2 (Ubuntu 14.2-1.pgdg20.04+1))
Type "help" for help.

postgres=# \c test
You are now connected to database "test" as user "postgres".
test=# select * from test;
 c1 
----
 1
(1 row)
```
