resource "yandex_vpc_network" "wp-network" {
  name = "wp-network"
}

resource "yandex_vpc_subnet" "wp-subnets" {
  for_each = var.subnets

  name           = each.value.name
  v4_cidr_blocks = each.value.blocks
  zone           = each.value.zone
  network_id     = yandex_vpc_network.wp-network.id
}
