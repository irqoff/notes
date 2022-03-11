# Homework 03

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
```

Create Docker network and start PostgreSQL server:
```
docker network create pg-net

docker run -d \
    --name postgres-14.2 \
    --net pg-net \
    -e POSTGRES_PASSWORD=mysecretpassword \
    -v /var/lib/postgres:/var/lib/postgresql/data \
    -p 5432:5432 \
    postgres:14.2
```

Connection from `psql`, create and populate a table:
```
root@postgresql:/home/ubuntu# docker run --net pg-net -it --rm postgres psql -h postgres-14.2 -U postgres
Password for user postgres: 
psql (14.2 (Debian 14.2-1.pgdg110+1))
Type "help" for help.

postgres=# SELECT version();
                                                           version                                                           
-----------------------------------------------------------------------------------------------------------------------------
 PostgreSQL 14.2 (Debian 14.2-1.pgdg110+1) on x86_64-pc-linux-gnu, compiled by gcc (Debian 10.2.1-6) 10.2.1 20210110, 64-bit
(1 row)

postgres=# CREATE TABLE cities (
    name            varchar(80),
    location        point
);
CREATE TABLE
postgres=# INSERT INTO cities VALUES ('San Francisco', '(-194.0, 53.0)');
INSERT 0 1
```

Connect from home laptop:
```
docker run -it --rm postgres psql -h $(terraform output nat_ip|tr -d \") -U postgres
Password for user postgres: 
psql (14.2 (Debian 14.2-1.pgdg110+1))
Type "help" for help.

postgres=# SELECT * FROM cities;
     name      | location  
---------------+-----------
 San Francisco | (-194,53)
(1 row)
```

Remove container and test data after creation a new one:
```
root@postgresql:/home/ubuntu# docker stop postgres-14.2
postgres-14.2
root@postgresql:/home/ubuntu# docker rm postgres-14.2
postgres-14.2
root@postgresql:/home/ubuntu#  docker run --net pg-net -it --rm postgres psql -h postgres-14.2 -U postgres
psql: error: could not translate host name "postgres-14.2" to address: Name or service not known
root@postgresql:/home/ubuntu# docker run -d \
>     --name postgres-14.2 \
>     --net pg-net \
>     -e POSTGRES_PASSWORD=mysecretpassword \
>     -v /var/lib/postgres:/var/lib/postgresql/data \
>     -p 5432:5432 \
>     postgres:14.2
74fc91f02485e75ffda1e3ccaf335f7759c5349dac9de5a0b6a71f03e4d7215e
root@postgresql:/home/ubuntu# docker run --net pg-net -it --rm postgres psql -h postgres-14.2 -U postgres
Password for user postgres: 
psql (14.2 (Debian 14.2-1.pgdg110+1))
Type "help" for help.

postgres=# SELECT * FROM cities;
     name      | location  
---------------+-----------
 San Francisco | (-194,53)
(1 row)
```

One my prolem is blocked 5432 connection by my VPN provider.

Destroy the VM:
```
terraform destroy
```
