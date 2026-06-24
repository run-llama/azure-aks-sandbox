# Managed Prometheus backing store: an Azure Monitor workspace plus association of the cluster
# with the workspace's default data collection rule, so the metrics add-on ships time-series here.

resource "azurerm_monitor_workspace" "prometheus" {
  name                = "${var.nuon_id}-prometheus"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.location
}

resource "azurerm_monitor_data_collection_rule_association" "prometheus" {
  name                    = "${var.nuon_id}-prometheus"
  target_resource_id      = module.aks.aks_id
  data_collection_rule_id = azurerm_monitor_workspace.prometheus.default_data_collection_rule_id
}
