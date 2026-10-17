output "deployment_token" {
  description = "The deployment token used to deploy code from CI pipelines."
  value       = module.static_web_app.deployment_token
  sensitive   = true
}
