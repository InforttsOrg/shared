variable "cloudflare_account_id" {
  type        = string
  description = "Cloudflare Account ID for Infortts Organization"
}

variable "cloudflare_api_token" {
  type        = string
  description = "Cloudflare API Token with R2 and DNS write permissions"
  sensitive   = true
}

variable "cloudflare_zone_id" {
  type        = string
  description = "Cloudflare DNS Zone ID for infortts.site"
  default     = ""
}

variable "bucket_name" {
  type        = string
  description = "Cloudflare R2 Bucket name for mobile OTA patches"
  default     = "infortts-ota-patches"
}

variable "ota_domain" {
  type        = string
  description = "Custom subdomain endpoint for OTA patch distribution"
  default     = "ota.infortts.site"
}

variable "environment" {
  type        = string
  description = "Deployment environment (production / staging)"
  default     = "production"
}
