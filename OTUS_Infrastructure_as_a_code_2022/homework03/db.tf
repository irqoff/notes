locals {
  dbuser     = yandex_mdb_mysql_user.user.name
  dbpassword = yandex_mdb_mysql_user.user.password
  dbhosts    = yandex_mdb_mysql_cluster.wp_mysql.host.*.fqdn
  dbname     = yandex_mdb_mysql_database.wp.name
}

resource "yandex_mdb_mysql_cluster" "wp_mysql" {
  name        = "wp-mysql"
  folder_id   = var.yc_folder
  environment = "PRODUCTION"
  network_id  = yandex_vpc_network.wp-network.id
  version     = "8.0"

  resources {
    resource_preset_id = "s2.micro"
    disk_type_id       = "network-ssd"
    disk_size          = 16
  }

  dynamic "host" {
    for_each = yandex_vpc_subnet.wp-subnets
    content {
      zone             = host.value.zone
      subnet_id        = host.value.id
      assign_public_ip = true
    }
  }
}

resource "yandex_mdb_mysql_database" "wp" {
  cluster_id = yandex_mdb_mysql_cluster.wp_mysql.id
  name       = "db"
}

resource "yandex_mdb_mysql_user" "user" {
    cluster_id = yandex_mdb_mysql_cluster.wp_mysql.id
    name                  = "user"
    password              = var.db_password
    authentication_plugin = "MYSQL_NATIVE_PASSWORD"
    permission {
      database_name = yandex_mdb_mysql_database.wp.name
      roles         = ["ALL"]
    }
}
