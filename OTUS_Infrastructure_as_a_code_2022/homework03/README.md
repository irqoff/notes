# homework02

In addition to the task and the task with double asterisk, I also did:
* parametized subnetworks by a variable
* parametized MySQL hosts by dynamic block
* use yandex_mdb_mysql_user and yandex_mdb_mysql_database to replace outdate blocks

terraform apply output:
```
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Outputs:

database_host_fqdn = tolist([
  "rc1a-7xsu9bm23vbdyvr7.mdb.yandexcloud.net",
  "rc1b-unes5wcsvlquw2wp.mdb.yandexcloud.net",
  "rc1c-w931lm9h6esiv6b1.mdb.yandexcloud.net",
])
load_balancer_public_ip = tolist([
  "51.250.66.225",
])
```
