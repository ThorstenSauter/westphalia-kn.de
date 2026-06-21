app_name                     = "westphalia-redirect"
primary_custom_domain_name   = "westphalia-kn.de"
secondary_custom_domain_name = "www.westphalia-kn.de"
env                          = "prod"
resource_id                  = "001"
resource_group_name          = "rg-westphalia-website-prod-001"
cloudflare_zone_name         = "westphalia-kn.de"
tags = {
  environment = "Production"
  managed-by  = "Terraform"
  project     = "Westphalia Website"
}
