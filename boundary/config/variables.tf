variable "tfc_organization" {
  type        = string
  description = "TFC Organization for remote state of infrastructure"
}

data "terraform_remote_state" "boundary_setup" {
  backend = "remote"

  config = {
    organization = var.tfc_organization
    workspaces = {
      name = "boundary-setup"
    }
  }
}

locals {
  vault_addr        = data.terraform_remote_state.boundary_setup.outputs.vault.address
  vault_namespace   = data.terraform_remote_state.boundary_setup.outputs.vault.namespace
  vault_admin_token = data.terraform_remote_state.boundary_setup.outputs.vault.token

  url      = data.terraform_remote_state.boundary_setup.outputs.boundary.url
  username = data.terraform_remote_state.boundary_setup.outputs.boundary.username
  password = data.terraform_remote_state.boundary_setup.outputs.boundary.password

  boundary_worker_mount   = data.terraform_remote_state.boundary_setup.outputs.boundary_worker_mount
  boundary_worker_eks_dns = data.terraform_remote_state.boundary_setup.outputs.boundary_worker_eks.private_dns
  boundary_worker_rds_dns = data.terraform_remote_state.boundary_setup.outputs.boundary_worker_rds.private_dns
}