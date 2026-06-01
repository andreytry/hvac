locals {
  project_root = abspath("${path.module}/..")
  source_hash = sha256(join("", [
    filesha256("${local.project_root}/dashboard/hvac-boc.html"),
    filesha256("${local.project_root}/Dockerfile"),
    filesha256("${local.project_root}/docker-compose.yml"),
  ]))
}

# ── SSH key ───────────────────────────────────────────────────────────────────
resource "hcloud_ssh_key" "default" {
  name       = "${var.server_name}-key"
  public_key = trimspace(file(var.ssh_public_key))

  lifecycle {
    ignore_changes = [name, public_key]
  }
}

# ── Firewall ──────────────────────────────────────────────────────────────────
resource "hcloud_firewall" "default" {
  name = "${var.server_name}-fw"

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "80"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "8080"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  rule {
    direction  = "in"
    protocol   = "icmp"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
}

# ── Server ────────────────────────────────────────────────────────────────────
resource "hcloud_server" "app" {
  name         = var.server_name
  server_type  = var.server_type
  image        = var.server_image
  location     = var.server_location
  ssh_keys     = [hcloud_ssh_key.default.id]
  firewall_ids = [hcloud_firewall.default.id]
  user_data    = file("${path.module}/cloud-init.yml")

  labels = {
    app = "hvac-boc"
  }

  lifecycle {
    ignore_changes = [user_data, ssh_keys, image]
  }
}

# ── Deploy: pack source → upload → build on server → run ─────────────────────
resource "null_resource" "deploy" {
  depends_on = [hcloud_server.app]

  triggers = {
    source_hash = local.source_hash
    server_id   = hcloud_server.app.id
  }

  provisioner "local-exec" {
    command = <<-EOT
      tar czf /tmp/hvac-boc-src.tar.gz \
        --exclude='.git' \
        --exclude='terraform' \
        --exclude='.idea' \
        --exclude='*.tar.gz' \
        -C ${local.project_root} .
    EOT
  }

  connection {
    type        = "ssh"
    host        = hcloud_server.app.ipv4_address
    user        = "root"
    private_key = file(var.ssh_private_key)
    timeout     = "10m"
    host_key    = ""
  }

  provisioner "remote-exec" {
    inline = [
      "until systemctl is-active --quiet docker; do echo 'Waiting for Docker...'; sleep 3; done",
      "echo 'Docker ready'",
      "rm -rf /opt/hvac-boc && mkdir -p /opt/hvac-boc"
    ]
  }

  provisioner "file" {
    source      = "/tmp/hvac-boc-src.tar.gz"
    destination = "/opt/hvac-boc/src.tar.gz"
  }

  provisioner "remote-exec" {
    inline = [
      "cd /opt/hvac-boc && tar xzf src.tar.gz",
      "cd /opt/hvac-boc && docker compose build",
      "cd /opt/hvac-boc && docker compose up -d",
      "echo 'Deployment complete — dashboard at http://$(curl -s ifconfig.me)'"
    ]
  }
}
