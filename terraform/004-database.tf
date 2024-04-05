resource "azurerm_mysql_flexible_server" "instance" {
  name                   = local.common.name
  resource_group_name    = azurerm_resource_group.instance.name
  location               = azurerm_resource_group.instance.location
  version                = "8.0.21"
  administrator_login    = local.common.admin_username
  administrator_password = local.common.admin_password
  zone                   = 2

  sku_name = "B_Standard_B1ms"

  geo_redundant_backup_enabled = false
}

resource "azurerm_mysql_flexible_database" "instance" {
  name                = local.common.name
  resource_group_name = azurerm_resource_group.instance.name
  server_name         = azurerm_mysql_flexible_server.instance.name
  charset             = "utf8mb3"
  collation           = "utf8mb3_unicode_ci"
}