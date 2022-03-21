terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.12.0"
    }
  }
}

provider "google" {
  credentials = var.credentials_file

  project = var.project
  region  = "europe-north1"
}

resource "google_compute_instance" "nginx" {
  name         = "nginx"
  machine_type = "e2-micro"
  zone         = "europe-north1-a"

  boot_disk {
    initialize_params {
      image = "ubuntu-2004-lts"
    }
  }

  network_interface {
    network = "default"

    access_config {
    }
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_key)}"
  }
}

resource "google_compute_instance" "prometheus" {
  name         = "prometheus"
  machine_type = "e2-micro"
  zone         = "europe-north1-a"

  boot_disk {
    initialize_params {
      image = "ubuntu-2004-lts"
    }
  }

  network_interface {
    network = "default"

    access_config {
    }
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_key)}"
  }
}

variable "credentials_file" {
  type = string
}
variable "project" {
  type = string
}
variable "ssh_key" {
  type = string
}

output "nginx_ip" {
  value = google_compute_instance.nginx.network_interface.0.access_config.0.nat_ip
}
output "nginx_internal_ip" {
  value = google_compute_instance.nginx.network_interface.0.network_ip
}
output "prometheus_ip" {
  value = google_compute_instance.prometheus.network_interface.0.access_config.0.nat_ip
}
