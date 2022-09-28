resource "yandex_lb_target_group" "wp_tg" {
  name = "wp-target-group"

  dynamic "target" {
    for_each = yandex_compute_instance.wp-apps
    content {
      subnet_id = target.value.network_interface.0.subnet_id
      address   = target.value.network_interface.0.ip_address
    }
  }
}

resource "yandex_lb_network_load_balancer" "wp_lb" {
  name = "wp-network-load-balancer"

  listener {
    name = "wp-listener"
    port = 80
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.wp_tg.id

    healthcheck {
      name = "tcp"
      tcp_options {
        port = 80
      }
    }
  }
}
