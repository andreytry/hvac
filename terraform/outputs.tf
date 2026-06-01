output "server_ip" {
  description = "Public IPv4 of the Hetzner server"
  value       = hcloud_server.app.ipv4_address
}

output "dashboard_url" {
  description = "HVAC BOC Dashboard URL"
  value       = "http://${hcloud_server.app.ipv4_address}"
}

output "ssh_command" {
  description = "SSH command to connect to the server"
  value       = "ssh -i ${var.ssh_private_key} root@${hcloud_server.app.ipv4_address}"
}

output "ssh_private_key" {
  description = "Path to SSH private key used for this server"
  value       = var.ssh_private_key
}

output "server_status" {
  description = "Server status"
  value       = hcloud_server.app.status
}
