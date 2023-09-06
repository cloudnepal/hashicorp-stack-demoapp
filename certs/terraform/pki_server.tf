resource "vault_mount" "consul_pki" {
  path                      = "consul/server/pki"
  type                      = "pki"
  description               = "PKI engine hosting intermediate Server CA1 v1 for Consul"
  default_lease_ttl_seconds = local.seconds_in_1_year
  max_lease_ttl_seconds     = local.seconds_in_3_years
}

resource "vault_pki_secret_backend_intermediate_cert_request" "consul_pki" {
  depends_on   = [vault_mount.consul_pki]
  backend      = vault_mount.consul_pki.path
  type         = "internal"
  common_name  = "Consul Server CA1 v1"
  key_type     = "rsa"
  key_bits     = "4096"
  ou           = var.cert_ou
  organization = var.cert_organization
  country      = var.cert_country
  locality     = var.cert_locality
  province     = var.cert_province
}

resource "local_file" "csr" {
  filename = "../server/intermediate/ca.csr"
  content  = vault_pki_secret_backend_intermediate_cert_request.consul_pki.csr
}

resource "vault_pki_secret_backend_intermediate_set_signed" "consul_pki" {
  count   = var.signed_cert ? 1 : 0
  backend = vault_mount.consul_pki.path

  certificate = var.signed_cert ? format("%s\n%s", file("../server/intermediate/ca.crt"), file("../server/root/ca.crt")) : null
}

resource "vault_mount" "consul_server_pki_int" {
  path                      = "consul/server/pki_int"
  type                      = "pki"
  description               = "PKI engine hosting intermediate Server CA2 v1 for Consul"
  default_lease_ttl_seconds = local.seconds_in_20_minutes
  max_lease_ttl_seconds     = local.seconds_in_1_year
}

resource "vault_pki_secret_backend_intermediate_cert_request" "consul_server_pki_int" {
  depends_on   = [vault_mount.consul_server_pki_int]
  backend      = vault_mount.consul_server_pki_int.path
  type         = "internal"
  common_name  = "Consul Server CA2 v1"
  key_type     = "rsa"
  key_bits     = "4096"
  ou           = var.cert_ou
  organization = var.cert_organization
  country      = var.cert_country
  locality     = var.cert_locality
  province     = var.cert_province
}

resource "vault_pki_secret_backend_root_sign_intermediate" "consul_server_pki_int" {
  count = var.signed_cert ? 1 : 0
  depends_on = [
    vault_mount.consul_pki,
    vault_pki_secret_backend_intermediate_cert_request.consul_server_pki_int,
  ]
  backend              = vault_mount.consul_pki.path
  csr                  = vault_pki_secret_backend_intermediate_cert_request.consul_server_pki_int.csr
  common_name          = "Consul Server CA2 v1.1"
  exclude_cn_from_sans = true
  ou                   = var.cert_ou
  organization         = var.cert_organization
  country              = "US"
  locality             = var.cert_locality
  province             = var.cert_province
  max_path_length      = 1
  ttl                  = local.seconds_in_1_year
}

resource "vault_pki_secret_backend_intermediate_set_signed" "consul_server_pki_int" {
  count       = var.signed_cert ? 1 : 0
  depends_on  = [vault_pki_secret_backend_root_sign_intermediate.consul_server_pki_int]
  backend     = vault_mount.consul_server_pki_int.path
  certificate = var.signed_cert ? format("%s\n%s", vault_pki_secret_backend_root_sign_intermediate.consul_server_pki_int.0.certificate, file("../server/intermediate/ca.crt")) : null
}