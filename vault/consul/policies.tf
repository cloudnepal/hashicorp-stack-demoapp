resource "vault_policy" "consul_gossip" {
  name = "consul-gossip"

  policy = <<EOT
path "${vault_mount.consul_static.path}/data/gossip" {
  capabilities = ["read"]
}
EOT
}

resource "vault_policy" "consul_bootstrap" {
  name = "consul-bootstrap"

  policy = <<EOT
path "${vault_mount.consul_static.path}/data/bootstrap" {
  capabilities = ["read"]
}
EOT
}

resource "vault_policy" "ca_policy" {
  name = "ca-policy"

  policy = <<EOT
path "${local.consul_pki_backend}/cert/ca" {
  capabilities = ["read"]
}
EOT
}

resource "vault_policy" "consul_cert" {
  name = "consul-server"

  policy = <<EOT
path "${local.consul_pki_backend}/issue/${vault_pki_secret_backend_role.consul_server.name}"
{
  capabilities = ["create","update"]
}
EOT
}

resource "vault_policy" "connect_ca" {
  name = "connect-ca"

  policy = <<EOT
path "/sys/mounts" {
  capabilities = [ "read" ]
}
path "/sys/mounts/connect_root" {
  capabilities = [ "create", "read", "update", "delete", "list" ]
}
path "/sys/mounts/${var.consul_datacenter}/connect_inter" {
  capabilities = [ "create", "read", "update", "delete", "list" ]
}
path "/connect_root/*" {
  capabilities = [ "create", "read", "update", "delete", "list" ]
}
path "/${var.consul_datacenter}/connect_inter/*" {
  capabilities = [ "create", "read", "update", "delete", "list" ]
}
EOT
}