# Managed Identity for AKS (Recommended)
resource "azurerm_container_registry" "instance" {
  name                     = local.common.name
  resource_group_name      = azurerm_resource_group.instance.name
  location                 = azurerm_resource_group.instance.location
  sku                      = "Basic"
  admin_enabled            = false
}

resource "azurerm_kubernetes_cluster" "instance" {
  name                = "${local.common.name}"
  location            = azurerm_resource_group.instance.location
  resource_group_name = azurerm_resource_group.instance.name
  dns_prefix          = "${local.common.name}"
  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_DS2_v2"
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
  }
}

resource "azurerm_role_assignment" "instance" {
  scope                = azurerm_container_registry.instance.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.instance.kubelet_identity[0].object_id
}