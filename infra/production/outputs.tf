output "deployment_token" {
  description = "The deployment token used to deploy code from CI pipelines."
  value       = azurerm_static_web_app.main.api_key
  sensitive   = true
}
