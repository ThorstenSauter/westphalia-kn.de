variable "app_name" {
  type        = string
  description = "The application name used in created resource names."
}

variable "primary_custom_domain_name" {
  type        = string
  description = "The apex custom domain bound to the static web app, validated via DNS TXT token."
}

variable "env" {
  type        = string
  description = "The shorthand name of the environment the infrastructure is deployed to."
}

variable "resource_id" {
  type        = string
  description = "The id appended to resource names in order to make them unique."
}

variable "location" {
  type        = string
  description = "The Azure region to deploy resources into."
}

variable "secondary_custom_domain_name" {
  type        = string
  description = "The subdomain (e.g. www) bound to the static web app, validated via CNAME delegation."
}

variable "sku" {
  type        = string
  description = "The SKU Name for the static web app."
  default     = "Free"
  validation {
    condition     = contains(["Free", "Standard"], var.sku)
    error_message = "The SKU has to be one of 'Free' or 'Standard'."
  }
}

variable "tags" {
  type        = map(string)
  description = "The default tags for Azure resources."
}

variable "cloudflare_zone_name" {
  type        = string
  description = "The Cloudflare zone name (domain) used to look up the zone ID."
}
