resource "yandex_compute_instance" "wp-apps" {
  for_each = yandex_vpc_subnet.wp-subnets

  name = "wp-app-${split("-", each.value.name)[2]}"
  zone = each.value.zone

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd80viupr3qjr5g6g9du"
    }
  }

  network_interface {
    subnet_id = each.value.id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/yc.pub")}"
  }
}
