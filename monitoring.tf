# Managed Prometheus backing store: an Azure Monitor workspace plus an explicit data collection
# endpoint and rule (in the install resource group) that forward cluster Prometheus metrics to the
# workspace, associated with the cluster so the metrics add-on ships time-series here.

resource "azurerm_monitor_workspace" "prometheus" {
  name                = "${var.nuon_id}-prometheus"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.location
}

resource "azurerm_monitor_data_collection_endpoint" "prometheus" {
  name                = "${var.nuon_id}-prometheus-dce"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.location
  kind                = "Linux"
}

resource "azurerm_monitor_data_collection_rule" "prometheus" {
  name                        = "${var.nuon_id}-prometheus-dcr"
  resource_group_name         = data.azurerm_resource_group.rg.name
  location                    = var.location
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.prometheus.id
  kind                        = "Linux"

  destinations {
    monitor_account {
      monitor_account_id = azurerm_monitor_workspace.prometheus.id
      name               = "MonitoringAccount1"
    }
  }

  data_flow {
    streams      = ["Microsoft-PrometheusMetrics"]
    destinations = ["MonitoringAccount1"]
  }

  data_sources {
    prometheus_forwarder {
      streams = ["Microsoft-PrometheusMetrics"]
      name    = "PrometheusDataSource"
    }
  }

  depends_on = [azurerm_monitor_data_collection_endpoint.prometheus]
}

resource "azurerm_monitor_data_collection_rule_association" "prometheus" {
  name                    = "${var.nuon_id}-prometheus"
  target_resource_id      = module.aks.aks_id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.prometheus.id
}
