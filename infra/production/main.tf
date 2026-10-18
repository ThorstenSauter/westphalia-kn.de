resource "azurerm_resource_group" "main" {
  name     = "rg-${var.app_name}-${var.env}-${var.resource_id}"
  location = var.location
  tags     = var.tags
}

module "static_web_app" {
  source               = "github.com/ThorstenSauter/cloudflare-azure-static-web-app?ref=1.1.0"
  name                 = "stapp-${var.app_name}-${var.env}-${var.resource_id}"
  resource_group_name  = azurerm_resource_group.main.name
  location             = azurerm_resource_group.main.location
  sku                  = var.sku
  tags                 = var.tags
  cloudflare_zone_name = var.cloudflare_zone_name
  subdomains           = ["www"]
}
