# main.tf

# 1. Obtenemos los datos de tu sesión actual de Azure (necesario para el Key Vault)
data "azurerm_client_config" "current" {}

# 2. Grupo de Recursos (La carpeta principal en la nube que contendrá todo)
resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.project_name}-${var.environment}"
  location = var.location
}

# 3. Storage Account (El Data Lake)
# Nota: El nombre debe ser único a nivel mundial, sin guiones ni mayúsculas
resource "azurerm_storage_account" "datalake" {
  name                     = "st${var.project_name}datalake${var.environment}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = true # Esto lo convierte en un Data Lake Gen2 real
}

# 4. Contenedores de la Arquitectura Medallón
resource "azurerm_storage_data_lake_gen2_filesystem" "medallion" {
  for_each           = toset(["bronze", "silver", "gold"])
  name               = each.key
  storage_account_id = azurerm_storage_account.datalake.id
}

# 5. Azure Data Factory (El Orquestador)
resource "azurerm_data_factory" "adf" {
  name                = "adf-${var.project_name}-${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# 6. Azure Key Vault (Bóveda para guardar secretos y credenciales)
resource "azurerm_key_vault" "kv" {
  name                        = "kv-${var.project_name}-${var.environment}"
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  sku_name                    = "standard"

  # Permisos para que tú (el administrador) puedas guardar y leer secretos
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge"
    ]
  }
}

# 7. Log Analytics Workspace y Action Group (Para monitoreo y alertas)
resource "azurerm_log_analytics_workspace" "law" {
  name                = "law-${var.project_name}-${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_monitor_action_group" "alerts" {
  name                = "ag-${var.project_name}-alerts"
  resource_group_name = azurerm_resource_group.rg.name
  short_name          = "RetailAlerts"

  email_receiver {
    name          = "AdminEmail"
    email_address = "johnalejandroruizgarzon@gmail.com" # Cámbialo por tu correo real
  }
}

# 8. Azure SQL Server y Base de Datos (Origen de nuestros datos)
resource "azurerm_mssql_server" "sqlserver" {
  name                         = "sql-${var.project_name}-${var.environment}"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = "adminretail"
  administrator_login_password = "SuperPassword2026!" # Contraseña segura obligatoria
}

# Regla de firewall para permitir que tu script Python local se conecte
resource "azurerm_mssql_firewall_rule" "allow_all" {
  name             = "AllowAll"
  server_id        = azurerm_mssql_server.sqlserver.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "255.255.255.255"
}

resource "azurerm_mssql_database" "sqldb" {
  name      = "RetailMaxDB" # Nombre explícito de la base de datos
  server_id = azurerm_mssql_server.sqlserver.id
  sku_name  = "Basic"       # Capa económica para pruebas
}