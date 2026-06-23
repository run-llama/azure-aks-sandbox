# Node Auto Provisioning (NAP) with Karpenter
#
# NAP is enabled via azapi_update_resource because the Azure/aks/azurerm module
# does not yet expose nodeProvisioningProfile natively.
#
# Enabling NAP triggers a long-running control-plane reconcile on the managed
# cluster (Karpenter CRDs + system components are rolled out). With the azapi
# provider's default operation timeout this PUT can race ahead of / out-live the
# reconcile, surfacing as a timeout or a transient "operation in progress"
# conflict and leaving the cluster stuck mid-update. We harden the step with an
# explicit long timeout and a backoff retry on the known transient error
# classes so the scripted terraform path no longer races. A cluster that did get
# stuck this way can be reconciled out-of-band with:
#   az aks update -g <rg> -n <name> --node-provisioning-mode Auto

resource "azapi_update_resource" "nap" {
  count = var.enable_nap ? 1 : 0

  type                    = "Microsoft.ContainerService/managedClusters@2025-05-01"
  resource_id             = module.aks.aks_id
  ignore_missing_property = true

  body = {
    properties = {
      nodeProvisioningProfile = {
        mode = "Auto"
      }
    }
  }

  timeouts {
    create = "60m"
    update = "60m"
    delete = "60m"
  }

  retry = {
    error_message_regex = [
      "OperationNotAllowed",
      "operation is in progress",
      "Operation is in progress",
      "another operation",
      "RetryableError",
      "context deadline exceeded",
      "Too Many Requests",
      "429",
      "timeout",
    ]
    interval_seconds     = 30
    max_interval_seconds = 180
    multiplier           = 1.5
  }

  depends_on = [module.aks]
}
