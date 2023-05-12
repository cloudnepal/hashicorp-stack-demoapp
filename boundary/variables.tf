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

variable "operations_team" {
  type = set(string)
}

variable "products_team" {
  type = set(string)
}

variable "leadership_team" {
  type = set(string)
}

variable "products_frontend_address" {
  type    = string
  default = ""
}

data "aws_instances" "eks" {
  instance_tags = {
    "eks:cluster-name" = local.eks_cluster_name
  }
}

locals {
  eks_cluster_name                 = data.terraform_remote_state.infrastructure.outputs.eks_cluster_name
  region                           = data.terraform_remote_state.infrastructure.outputs.region
  url                              = data.terraform_remote_state.infrastructure.outputs.hcp_boundary_endpoint
  username                         = data.terraform_remote_state.infrastructure.outputs.hcp_boundary_username
  password                         = data.terraform_remote_state.infrastructure.outputs.hcp_boundary_password
  eks_target_ips                   = toset(data.aws_instances.eks.private_ips)
  products_database_target_address = data.terraform_remote_state.infrastructure.outputs.product_database_address
}