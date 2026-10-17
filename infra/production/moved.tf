# Moved into the cloudflare-azure-static-web-app module. Keep these until every state has been applied with them.
moved {
  from = azurerm_static_web_app.main
  to   = module.static_web_app.azurerm_static_web_app.main
}

moved {
  from = azurerm_static_web_app_custom_domain.primary
  to   = module.static_web_app.azurerm_static_web_app_custom_domain.apex["westphalia-kn.de"]
}

moved {
  from = azurerm_static_web_app_custom_domain.secondary
  to   = module.static_web_app.azurerm_static_web_app_custom_domain.subdomain["www"]
}

moved {
  from = cloudflare_dns_record.primary_validation
  to   = module.static_web_app.cloudflare_dns_record.apex_validation["westphalia-kn.de"]
}

moved {
  from = cloudflare_dns_record.primary
  to   = module.static_web_app.cloudflare_dns_record.apex["westphalia-kn.de"]
}

moved {
  from = cloudflare_dns_record.secondary
  to   = module.static_web_app.cloudflare_dns_record.subdomain["www"]
}

moved {
  from = time_sleep.dns_propagation
  to   = module.static_web_app.time_sleep.dns_propagation[0]
}
