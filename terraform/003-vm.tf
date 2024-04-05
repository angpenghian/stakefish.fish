# Public IP for SSH access
resource "azurerm_public_ip" "instance" {
  name                = "${local.common.name}_ip"
  location            = azurerm_resource_group.instance.location
  resource_group_name = azurerm_resource_group.instance.name
  allocation_method   = "Dynamic"
}

# Network interface
resource "azurerm_network_interface" "instance" {
  name                = "${local.common.name}_nic"
  location            = azurerm_resource_group.instance.location
  resource_group_name = azurerm_resource_group.instance.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.instance.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.instance.id
  }
}

# Virtual machine ( runner )
resource "azurerm_linux_virtual_machine" "instance" {
  name                = "${local.common.name}_vm"
  computer_name       = "runner"
  resource_group_name = azurerm_resource_group.instance.name
  location            = azurerm_resource_group.instance.location
  size                = local.common.vm_size
  disable_password_authentication = false
  user_data = base64encode(templatefile("${path.module}/bash_scripts/install-docker-kubernetes-jenkins.sh", {}))
  network_interface_ids = [
    azurerm_network_interface.instance.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  admin_username = local.common.admin_username
  admin_password = local.common.admin_password
}