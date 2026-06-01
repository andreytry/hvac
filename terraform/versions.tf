terraform {
  required_version = ">= 1.5.0"

  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.49"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}
