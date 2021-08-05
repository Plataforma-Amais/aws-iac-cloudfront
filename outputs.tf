output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.application_cf_distribution.id
  description = "Name of created distribution."
}
output "cloudfront_distribution_origin" {
  value = aws_cloudfront_distribution.application_cf_distribution.origin
  description = "Distribution origin."
}
output "cloudfront_distribution_arn" {
  value = aws_cloudfront_distribution.application_cf_distribution.arn
  description = "Distribution ARN."
}
output "cloudfront_distribution_aliases" {
  value = [for alias in aws_cloudfront_distribution.application_cf_distribution.aliases: "http://${alias}"]
  description = "Distribution domain aliases."
}
output "cloudfront_distribution_domain_name" {
  value = "https://${aws_cloudfront_distribution.application_cf_distribution.domain_name}"
  description = "Distribution domain name."
}
output "cloudfront_distribution_logging_config" {
  value = aws_cloudfront_distribution.application_cf_distribution.logging_config
  description = "Distribution logging config."
}
output "buckets_name" {
  value = [
    { access_log_bucket = "s3://${module.s3_bucket_for_application_cf_log.s3_bucket_id}"},
    { statics_bucket = "s3://${module.s3_bucket_for_application_cf_client.s3_bucket_id}"}
  ]
  description = "Touple contains the names of created buckets."
}
output "r53_records" {
  value = [for rec in aws_route53_record.r53_public_zone_record_cf: "${rec["fqdn"]} => ${element(tolist(rec["records"]), 0)}"]
  description = "List of created subdomains."
}