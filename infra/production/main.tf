data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

resource "azurerm_static_web_app" "main" {
  name                = "stapp-${var.app_name}-${var.env}-${var.resource_id}"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  sku_tier            = var.sku
  sku_size            = var.sku
  tags                = var.tags

  lifecycle {
    ignore_changes = [
      repository_branch,
      repository_url
    ]
  }
}

resource "azurerm_static_web_app_custom_domain" "primary" {
  static_web_app_id = azurerm_static_web_app.main.id
  domain_name       = var.primary_custom_domain_name
  validation_type   = "dns-txt-token"
}

resource "azurerm_static_web_app_custom_domain" "secondary" {
  static_web_app_id = azurerm_static_web_app.main.id
  domain_name       = var.secondary_custom_domain_name
  validation_type   = "cname-delegation"
}
