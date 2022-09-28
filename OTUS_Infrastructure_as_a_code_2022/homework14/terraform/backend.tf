terraform {
  backend "http" {
    address="https://gitlab.com/api/v4/projects/39786962/terraform/state/iacstate"
    lock_address="https://gitlab.com/api/v4/projects/39786962/terraform/state/iacstate/lock"
    unlock_address="https://gitlab.com/api/v4/projects/39786962/terraform/state/iacstate/lock"
    username="irqoff"
    lock_method="POST"
    unlock_method="DELETE"
    retry_wait_min=5
  }
}
