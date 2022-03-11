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

data "google_compute_network" "default" {
  name = "default"
}

resource "google_compute_instance" "postgresql" {
  name         = "postgresql"
  machine_type = "e2-micro"
  zone         = "europe-north1-a"

  boot_disk {
    initialize_params {
      image = "ubuntu-2004-lts"
    }
  }

  network_interface {
    network = data.google_compute_network.default.self_link

    access_config {
    }
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_key)}"
  }
}

resource "google_compute_firewall" "default" {
  name    = "postgresql-firewall"
  network = data.google_compute_network.default.name

  allow {
    protocol = "tcp"
    ports    = ["5432"]
  }

  source_ranges = ["0.0.0.0/0"]
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

output "nat_ip" {
  value = google_compute_instance.postgresql.network_interface.0.access_config.0.nat_ip
}
