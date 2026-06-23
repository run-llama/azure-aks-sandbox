# NAP/Karpenter provisions nodes into the BYO-VNet (the vnet/subnets are passed in
# as data sources, see network.tf). For Karpenter to read and join that subnet, the
# AKS cluster's control-plane managed identity needs Network access to the existing
# vnet. Without this, AKSNodeClass reconciliation fails with a 403
# (SubnetUnknownError -> Microsoft.Network/virtualNetworks/subnets/read denied) and
# Karpenter cannot provision any nodes -- the nodeclasses stay Ready=False.
#
# This is the standard AKS BYO-VNet requirement (grant the cluster identity
# "Network Contributor" on the vnet). Only needed when NAP is enabled.
resource "azurerm_role_assignment" "aks_vnet_network_contributor" {
  count = var.enable_nap ? 1 : 0

  scope                = data.azurerm_virtual_network.existing.id
  role_definition_name = "Network Contributor"
  principal_id         = module.aks.cluster_identity.principal_id
}
