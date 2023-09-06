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

resource "vault_policy" "consul_api_gateway" {
  name = "consul-api-gateway"

  policy = <<EOT
path "${local.consul_gateway_pki_backend}/issue/${vault_pki_secret_backend_role.consul_gateway.name}"
{
  capabilities = ["create","update"]
}

path "${local.consul_gateway_pki_backend}/sign/${vault_pki_secret_backend_role.consul_gateway.name}"
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

path "/sys/mounts/${var.vault_consul_connect_pki_root_backend}" {
  capabilities = [ "read" ]
}

path "/sys/mounts/${var.vault_consul_connect_pki_int_backend}" {
  capabilities = [ "read" ]
}

path "/${var.vault_consul_connect_pki_root_backend}/" {
  capabilities = [ "read" ]
}

path "/${var.vault_consul_connect_pki_root_backend}/root/sign-intermediate" {
  capabilities = [ "update" ]
}

path "/${var.vault_consul_connect_pki_int_backend}/*" {
  capabilities = [ "create", "read", "update", "delete", "list" ]
}
EOT
}

resource "vault_policy" "connect_ca_hcp" {
  name = "connect-ca-hcp"

  policy = <<EOT
path "auth/token/lookup-self" {
    capabilities = ["read"]
}

path "/sys/mounts" {
  capabilities = [ "read" ]
}

path "/sys/mounts/connect_root" {
  capabilities = [ "create", "read", "update", "delete", "list" ]
}

path "/sys/mounts/connect_inter" {
  capabilities = [ "create", "read", "update", "delete", "list" ]
}

path "/sys/mounts/connect_inter/tune" {
  capabilities = [ "create", "read", "update", "delete", "list" ]
}

path "/connect_root/*" {
  capabilities = [ "create", "read", "update", "delete", "list" ]
}

path "/connect_inter/*" {
  capabilities = [ "create", "read", "update", "delete", "list" ]
}
EOT
}