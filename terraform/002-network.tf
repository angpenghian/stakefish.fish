resource "azurerm_resource_group" "instance" {
  name     = "${local.common.name}_rg"
  location = local.common.region
}

# virtual network
resource "azurerm_virtual_network" "instance" {
  name                = "${local.common.name}_vnet"
  address_space       = [local.common.vnet_cidr]
  location            = azurerm_resource_group.instance.location
  resource_group_name = azurerm_resource_group.instance.name
}

# subnet
resource "azurerm_subnet" "instance" {
  name                 = "${local.common.name}_subnet"
  resource_group_name  = azurerm_resource_group.instance.name
  virtual_network_name = azurerm_virtual_network.instance.name
  address_prefixes     = [local.common.subnet_cidr]
}