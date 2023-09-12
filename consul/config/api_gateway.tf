locals {
  consul_api_gateway_secret_name            = "consul-api-gateway"
  consul_api_gateway_kubernetes_secret_name = "consul-api-gateway-cert"
}

resource "kubernetes_service_account" "consul_api_gateway" {
  metadata {
    name      = "consul-api-gateway"
    namespace = var.namespace
  }
  automount_service_account_token = true
}

## Commenting out for now due to lack of support for direct Vault PKI.
## https://github.com/hashicorp/consul-api-gateway/issues/208.

resource "kubernetes_manifest" "consul_api_gateway_secret_provider" {
  depends_on = [
    kubernetes_service_account.consul_api_gateway
  ]
  manifest = {
    "apiVersion" = "secrets-store.csi.x-k8s.io/v1"
    "kind"       = "SecretProviderClass"
    "metadata" = {
      "name"      = local.consul_api_gateway_secret_name
      "namespace" = var.namespace
    }
    "spec" = {
      "parameters" = {
        "objects"        = <<-EOT
      - objectName: "consul-api-gateway-ca-cert"
        method: "POST"
        secretPath: "consul/gateway/pki_int/issue/${kubernetes_service_account.consul_api_gateway.metadata.0.name}"
        secretKey: "certificate"
        secretArgs:
          common_name: "gateway.${local.certificate_allowed_domain}"
      - objectName: "consul-api-gateway-ca-key"
        method: "POST"
        secretPath: "consul/gateway/pki_int/issue/${kubernetes_service_account.consul_api_gateway.metadata.0.name}"
        secretKey: "private_key"
        secretArgs:
          common_name: "gateway.${local.certificate_allowed_domain}"
      EOT
        "roleName"       = kubernetes_service_account.consul_api_gateway.metadata.0.name
        "vaultAddress"   = local.vault_addr
        "vaultNamespace" = "admin"
      }
      "provider" = "vault"
      "secretObjects" = [
        {
          "data" = [
            {
              "key"        = "tls.crt"
              "objectName" = "consul-api-gateway-ca-cert"
            },
            {
              "key"        = "tls.key"
              "objectName" = "consul-api-gateway-ca-key"
            },
          ]
          "secretName" = local.consul_api_gateway_kubernetes_secret_name
          "type"       = "kubernetes.io/tls"
        },
      ]
    }
  }
}

resource "kubernetes_manifest" "csi_secrets_store_inline" {
  depends_on = [
    kubernetes_manifest.consul_api_gateway_secret_provider
  ]
  manifest = {
    "apiVersion" = "apps/v1"
    "kind"       = "Deployment"
    "metadata" = {
      "labels" = {
        "app" = "secrets-store-inline"
      }
      "name"      = "secrets-store-inline"
      "namespace" = var.namespace
    }
    "spec" = {
      "replicas" = 1
      "selector" = {
        "matchLabels" = {
          "app" = "secrets-store-inline"
        }
      }
      "template" = {
        "metadata" = {
          "labels" = {
            "app" = "secrets-store-inline"
          }
        }
        "spec" = {
          "containers" = [
            {
              "command" = [
                "/bin/sleep",
                "10000",
              ]
              "image" = "k8s.gcr.io/e2e-test-images/busybox:1.29"
              "name"  = "busybox"
              "volumeMounts" = [
                {
                  "mountPath" = "/mnt/secrets-store"
                  "name"      = "secrets-store"
                  "readOnly"  = true
                },
              ]
            },
          ]
          "serviceAccountName" = kubernetes_service_account.consul_api_gateway.metadata.0.name
          "volumes" = [
            {
              "csi" = {
                "driver"   = "secrets-store.csi.k8s.io"
                "readOnly" = true
                "volumeAttributes" = {
                  "secretProviderClass" = local.consul_api_gateway_secret_name
                }
              }
              "name" = "secrets-store"
            },
          ]
        }
      }
    }
  }
}

resource "kubernetes_manifest" "api_gateway" {
  depends_on = [
    kubernetes_manifest.consul_api_gateway_secret_provider,
    kubernetes_manifest.csi_secrets_store_inline
  ]
  manifest = {
    "apiVersion" = "gateway.networking.k8s.io/v1beta1"
    "kind"       = "Gateway"
    "metadata" = {
      "name"      = "api-gateway"
      "namespace" = var.namespace
    }
    "spec" = {
      "gatewayClassName" = "consul-api-gateway"
      "listeners" = [
        {
          "allowedRoutes" = {
            "namespaces" = {
              "from" = "All"
            }
          }
          "name"     = "https"
          "port"     = 443
          "protocol" = "HTTPS"
          "tls" = {
            "certificateRefs" = [
              {
                "name" = local.consul_api_gateway_kubernetes_secret_name
              },
            ]
          }
        },
      ]
    }
  }
}

resource "kubernetes_manifest" "consul_api_gateway_tokenreview_binding" {
  manifest = {
    "apiVersion" = "rbac.authorization.k8s.io/v1"
    "kind"       = "ClusterRoleBinding"
    "metadata" = {
      "name" = "consul-api-gateway-tokenreview-binding"
    }
    "roleRef" = {
      "apiGroup" = "rbac.authorization.k8s.io"
      "kind"     = "ClusterRole"
      "name"     = "system:auth-delegator"
    }
    "subjects" = [
      {
        "kind"      = "ServiceAccount"
        "name"      = kubernetes_service_account.consul_api_gateway.metadata.0.name
        "namespace" = kubernetes_service_account.consul_api_gateway.metadata.0.namespace
      },
    ]
  }
}

resource "kubernetes_manifest" "consul_api_gateway_auth" {
  manifest = {
    "apiVersion" = "rbac.authorization.k8s.io/v1"
    "kind"       = "ClusterRole"
    "metadata" = {
      "name" = "consul-api-gateway-auth"
    }
    "rules" = [
      {
        "apiGroups" = [
          "",
        ]
        "resources" = [
          "serviceaccounts",
        ]
        "verbs" = [
          "get",
        ]
      },
    ]
  }
}

resource "kubernetes_manifest" "consul_api_gateway_auth_binding" {
  manifest = {
    "apiVersion" = "rbac.authorization.k8s.io/v1"
    "kind"       = "ClusterRoleBinding"
    "metadata" = {
      "name" = "consul-api-gateway-auth-binding"
    }
    "roleRef" = {
      "apiGroup" = "rbac.authorization.k8s.io"
      "kind"     = "ClusterRole"
      "name"     = kubernetes_manifest.consul_api_gateway_auth.manifest.metadata.name
    }
    "subjects" = [
      {
        "kind"      = "ServiceAccount"
        "name"      = kubernetes_service_account.consul_api_gateway.metadata.0.name
        "namespace" = kubernetes_service_account.consul_api_gateway.metadata.0.namespace
      },
    ]
  }
}

resource "kubernetes_manifest" "consul_auth_binding" {
  manifest = {
    "apiVersion" = "rbac.authorization.k8s.io/v1"
    "kind"       = "ClusterRoleBinding"
    "metadata" = {
      "name" = "consul-auth-binding"
    }
    "roleRef" = {
      "apiGroup" = "rbac.authorization.k8s.io"
      "kind"     = "ClusterRole"
      "name"     = kubernetes_manifest.consul_api_gateway_auth.manifest.metadata.name
    }
    "subjects" = [
      {
        "kind"      = "ServiceAccount"
        "name"      = kubernetes_service_account.consul_api_gateway.metadata.0.name
        "namespace" = kubernetes_service_account.consul_api_gateway.metadata.0.namespace
      },
    ]
  }
}