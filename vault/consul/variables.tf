variable "use_vault_root_ca" {
  type        = bool
  description = "Use Vault to generate root CAs. Recommended for development purposes only."
  default     = false
}

variable "consul_gossip_key" {
  type        = string
  sensitive   = true
  description = "Consul's Gossip Encryption Key. Generate with `consul keygen`."
}

variable "consul_datacenter" {
  type        = string
  description = "Consul datacenter in Kubernetes cluster"
  default     = "dc1"
}

variable "consul_namespace" {
  type        = string
  description = "Kubernetes namespace for Consul cluster"
  default     = "consul"
}

variable "consul_api_gateway_allowed_domain" {
  type        = string
  description = "Allowed domain for Consul API Gateway certificates"
  default     = "hashiconf.example.com"
}

variable "vault_consul_pki_root_backend" {
  type        = string
  description = "Vault PKI secrets engine for Consul Root CA"
  default     = "consul/server/pki"
}

variable "vault_consul_pki_int_backend" {
  type        = string
  description = "Vault PKI secrets engine for Consul Intermediate CA"
  default     = "consul/server/pki_int"
}

variable "vault_consul_connect_pki_root_backend" {
  type        = string
  description = "Vault PKI secrets engine for Consul Connect Root CA"
  default     = "consul/connect/pki"
}

variable "vault_consul_connect_pki_int_backend" {
  type        = string
  description = "Vault PKI secrets engine for Consul Connect Intermediate CA"
  default     = "consul/connect/pki_int"
}

variable "vault_consul_gateway_pki_root_backend" {
  type        = string
  description = "Vault PKI secrets engine for Consul API Gateway CA"
  default     = "consul/gateway/pki"
}

variable "vault_consul_gateway_pki_int_backend" {
  type        = string
  description = "Vault PKI secrets engine for Consul API Gateway Intermediate CA"
  default     = "consul/gateway/pki_int"
}

variable "cert_ou" {
  default     = "HashiConf"
  type        = string
  description = "Certificate organization unit"
}

variable "cert_organization" {
  default     = "HashiCorp"
  type        = string
  description = "Certificate organization"
}

variable "cert_country" {
  default     = "US"
  type        = string
  description = "Certificate country"
}

variable "cert_locality" {
  default     = "San Francisco"
  type        = string
  description = "Certificate locality (city)"
}

variable "cert_province" {
  default     = "California"
  type        = string
  description = "Certificate province (state)"
}

variable "tfc_organization" {
  type        = string
  description = "TFC Organization for remote state of infrastructure"
}

data "terraform_remote_state" "infrastructure" {
  backend = "remote"

  config = {
    organization = var.tfc_organization
    workspaces = {
      name = "infrastructure"
    }
  }
}

data "terraform_remote_state" "setup" {
  backend = "remote"

  config = {
    organization = var.tfc_organization
    workspaces = {
      name = "vault-setup"
    }
  }
}

locals {
  hcp_vault_cluster_id      = var.hcp_vault_cluster_id == "" ? data.terraform_remote_state.infrastructure.outputs.hcp_vault_cluster : var.hcp_vault_cluster_id
  hcp_vault_public_address  = data.terraform_remote_state.infrastructure.outputs.hcp_vault_public_address
  hcp_vault_private_address = data.terraform_remote_state.infrastructure.outputs.hcp_vault_private_address
  hcp_vault_namespace       = data.terraform_remote_state.infrastructure.outputs.hcp_vault_namespace
  hcp_vault_cluster_token   = var.hcp_vault_cluster_token == "" ? data.terraform_remote_state.infrastructure.outputs.hcp_vault_token : var.hcp_vault_cluster_token

  hcp_consul_public_address  = data.terraform_remote_state.infrastructure.outputs.hcp_consul_public_address
  hcp_consul_private_address = data.terraform_remote_state.infrastructure.outputs.hcp_consul_private_address
  hcp_consul_token           = data.terraform_remote_state.infrastructure.outputs.hcp_consul_token

  vault_kubernetes_auth_path = data.terraform_remote_state.setup.outputs.vault_kubernetes_auth_path
}

variable "hcp_vault_cluster_id" {
  type        = string
  description = "HCP Vault Cluster ID for configuration"
  default     = ""
}

variable "hcp_vault_cluster_token" {
  type        = string
  description = "HCP Vault Cluster token for configuration"
  default     = ""
  sensitive   = true
}