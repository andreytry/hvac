# ── Hetzner Cloud ─────────────────────────────────────────────────────────────
variable "hcloud_token" {
  description = "Hetzner Cloud API token (generate at https://console.hetzner.cloud)"
  type        = string
  sensitive   = true
}

variable "server_name" {
  description = "Name for the Hetzner server"
  type        = string
  default     = "hvac-ui"
}

variable "server_type" {
  description = "Hetzner server type (cpx11 = 2 vCPU, 2 GB RAM)"
  type        = string
  default     = "cpx11"
}

variable "server_location" {
  description = "Hetzner datacenter location"
  type        = string
  default     = "ash" # Ashburn VA — matches existing server
}

variable "server_image" {
  description = "OS image for the server"
  type        = string
  default     = "ubuntu-24.04"
}

variable "ssh_public_key" {
  description = "Path to your SSH public key file"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "ssh_private_key" {
  description = "Path to your SSH private key file (used by Terraform provisioners)"
  type        = string
  default     = "~/.ssh/id_ed25519"
}
