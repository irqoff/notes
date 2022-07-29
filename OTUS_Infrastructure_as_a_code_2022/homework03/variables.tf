variable "yc_cloud" {
  type        = string
  description = "Yandex Cloud ID"
}

variable "yc_folder" {
  type        = string
  description = "Yandex Cloud folder"
}

variable "yc_token" {
  type        = string
  description = "Yandex Cloud OAuth token"
}

variable "db_password" {
  description = "MySQL user pasword"
}

variable "subnets" {
  type = map(object({
    name   = string
    zone   = string
    blocks = list(string)
  }))
  default = {
    a = {
      name   = "wp-subnet-a"
      zone   = "ru-central1-a"
      blocks = ["10.2.0.0/16"]
    },
    b = {
      name   = "wp-subnet-b"
      zone   = "ru-central1-b"
      blocks = ["10.3.0.0/16"]
    },
    c = {
      name   = "wp-subnet-c"
      zone   = "ru-central1-c"
      blocks = ["10.4.0.0/16"]
    }
  }
}
