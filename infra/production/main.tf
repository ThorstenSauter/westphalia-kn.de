data "cloudflare_zone" "main" {
  filter = {
    name = var.cloudflare_zone_name
  }
}

resource "azurerm_resource_group" "main" {
  name     = "rg-${var.app_name}-${var.env}-${var.resource_id}"
  location = var.location
  tags     = var.tags
}

resource "azurerm_static_web_app" "main" {
  name                = "stapp-${var.app_name}-${var.env}-${var.resource_id}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
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

  depends_on = [time_sleep.dns_propagation]
}

# TXT record used by Azure to validate apex domain ownership.
resource "cloudflare_dns_record" "primary_validation" {
  zone_id = data.cloudflare_zone.main.id
  name    = var.primary_custom_domain_name
  type    = "TXT"
  content = azurerm_static_web_app_custom_domain.primary.validation_token
  ttl     = 3600

  lifecycle {
    ignore_changes = [content]
  }
}

# Cloudflare flattens this CNAME at the apex to A/AAAA records automatically.
resource "cloudflare_dns_record" "primary" {
  zone_id = data.cloudflare_zone.main.id
  name    = var.primary_custom_domain_name
  type    = "CNAME"
  content = azurerm_static_web_app.main.default_host_name
  proxied = false
  ttl     = 3600
}

# CNAME serves as both routing and cname-delegation validation for www.
resource "cloudflare_dns_record" "secondary" {
  zone_id = data.cloudflare_zone.main.id
  name    = var.secondary_custom_domain_name
  type    = "CNAME"
  content = azurerm_static_web_app.main.default_host_name
  proxied = false
  ttl     = 3600
}

# Waits for DNS propagation before Azure attempts cname-delegation validation.
resource "time_sleep" "dns_propagation" {
  create_duration = "120s"

  depends_on = [
    cloudflare_dns_record.primary_validation,
    cloudflare_dns_record.primary,
    cloudflare_dns_record.secondary,
  ]
}
