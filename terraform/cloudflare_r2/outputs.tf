output "r2_bucket_name" {
  value       = cloudflare_r2_bucket.ota_bucket.name
  description = "Name of the provisioned Cloudflare R2 bucket"
}

output "r2_bucket_id" {
  value       = cloudflare_r2_bucket.ota_bucket.id
  description = "Resource ID of the Cloudflare R2 bucket"
}

output "r2_s3_endpoint" {
  value       = "https://${var.cloudflare_account_id}.r2.cloudflarestorage.com"
  description = "S3-compatible API endpoint for uploading patches via AWS CLI / rclone"
}

output "ota_public_url" {
  value       = "https://${var.ota_domain}"
  description = "Public CDN endpoint for downloading patches in Infortts mobile apps"
}
