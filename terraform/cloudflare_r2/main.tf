# ==============================================================================
# INFORTTS CLOUDFLARE R2 OTA STORAGE & DISTRIBUTION INFRASTRUCTURE
# ==============================================================================

# 1. Cloudflare R2 Storage Bucket for Infortts Mobile OTA Patches
resource "cloudflare_r2_bucket" "ota_bucket" {
  account_id = var.cloudflare_account_id
  name       = var.bucket_name
  location   = "WNAM"
}

# 2. CNAME DNS Record for Public Zero-Egress CDN Endpoint (ota.infortts.site)
resource "cloudflare_record" "ota_cname" {
  count   = var.cloudflare_zone_id != "" ? 1 : 0
  zone_id = var.cloudflare_zone_id
  name    = "ota"
  value   = "${var.cloudflare_account_id}.r2.cloudflarestorage.com"
  type    = "CNAME"
  proxied = true
  ttl     = 1
  comment = "Infortts Mobile OTA Patch CDN Endpoint"
}
