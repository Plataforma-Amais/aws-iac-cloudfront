data "aws_route53_zone" "r53_hosted_zone" {
  zone_id = var.r53_hosted_zone_id
}

data "aws_acm_certificate" "acm_certificate" {
  domain = data.aws_route53_zone.r53_hosted_zone.name
  depends_on = [
    data.aws_route53_zone.r53_hosted_zone
  ]
}

locals {
  cf_distribution_environment = terraform.workspace != null ? terraform.workspace : var.cf_distribution_environment
  cf_distribution_name = "${var.cf_distribution_name}-${local.cf_distribution_environment == "production" ? "prod" : local.cf_distribution_environment == "develop" ? "dev" : "stg"}"
  cf_subdomain_name = [ for record_name in var.r53_record_name: "${record_name}.${data.aws_route53_zone.r53_hosted_zone.name}" ]
  acm_certificate_arn = data.aws_acm_certificate.acm_certificate.arn
}

# Buckets
module "s3_bucket_for_application_cf_client" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = local.cf_distribution_name
  acl    = "private"

  versioning = {
    enabled = true
  }

  tags = {
    Terraform   = true  
    Environment = local.cf_distribution_environment
    CostCenter  = "Global" 
    Project     = local.cf_distribution_name
  }
}
module "s3_bucket_for_application_cf_log" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = "${local.cf_distribution_name}-cf-logs"
  acl    = "log-delivery-write"

  # Allow deletion of non-empty bucket
  force_destroy = true

  attach_elb_log_delivery_policy = true

  tags = {
    Terraform   = true  
    Environment = local.cf_distribution_environment
    CostCenter  = "Global" 
    Project     = local.cf_distribution_name
  }
}

# Policy

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = local.cf_distribution_name
}

resource "aws_s3_bucket_policy" "s3_bucket_policy" {
  bucket = module.s3_bucket_for_application_cf_client.s3_bucket_id
  policy = <<POLICY
{
  "Version": "2008-10-17",
  "Id": "PolicyCFPrivContent-${var.cf_distribution_name}",
  "Statement": [
    {
      "Sid": "1",
      "Effect": "Allow",
      "Principal": {
        "AWS": "${aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn}"
      },
      "Action": "s3:GetObject",
      "Resource": "${module.s3_bucket_for_application_cf_client.s3_bucket_arn}/*"
    }
  ]
}
POLICY

  depends_on = [
    module.s3_bucket_for_application_cf_client,
    aws_cloudfront_origin_access_identity.origin_access_identity
  ]

}

resource "aws_iam_policy" "iam_user_policy" {
  name        = "pol-${local.cf_distribution_name}"
  description = "A policy for especified user userd for deploy objects"

  policy = jsonencode({
    Version = "2012-10-17"
    "Statement" : [
      {
        "Sid" : "AllowListAllBuckets",
        "Effect" : "Allow",
        "Action" : "s3:ListAllMyBuckets",
        "Resource" : "*"
      },
      {
        "Sid" : "AllowReadAndWrite",
        "Effect" : "Allow",
        "Action" : [
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:GetObject*",
          "ListObjectsV2",
          "ListObject*",
          "s3:PutObject",
          "s3:PutObjectAcl"
        ],
        "Resource" : "${module.s3_bucket_for_application_cf_client.s3_bucket_arn}/*"
      },
      {
        "Sid" : "AllowManagementInvalidations",
        "Effect" : "Allow",
        "Action" : [
          "cloudfront:ListInvalidations",
          "cloudfront:GetInvalidation",
          "cloudfront:CreateInvalidation"
        ],
        "Resource" : [
          aws_cloudfront_distribution.application_cf_distribution.arn
        ]
      }
    ]
  })

  depends_on = [
    aws_cloudfront_distribution.application_cf_distribution,
    module.s3_bucket_for_application_cf_client
  ]
}

resource "aws_iam_user_policy_attachment" "iam_user_policy_attach" {
  count      = var.iam_user_name_to_attatch_deploy_policy != null ? 1 : 0
  user       = var.iam_user_name_to_attatch_deploy_policy
  policy_arn = aws_iam_policy.iam_user_policy.arn
  depends_on = [
    aws_iam_policy.iam_user_policy
  ]
}

resource "aws_s3_bucket_object" "s3_bucket_for_application_cf_client_index_object" {
  bucket = module.s3_bucket_for_application_cf_client.s3_bucket_id
  key = "current/index.html"
  content_type = "text/html"
  content = <<HTML
<!DOCTYPE html>
<html>
<head>
  <meta charset='utf-8'>
  <meta http-equiv='X-UA-Compatible' content='IE=edge'>
  <title>Plataforma A+ CloudFront distribution example, by SRE Team.</title>
  <meta name='viewport' content='width=device-width, initial-scale=1'>
</head>
<body>
  <center>
    <p><a href='https://www.plataformaamais.com.br/' target='blank'><img src='https://www.plataformaamais.com.br/wp-content/uploads/2021/01/logo.png' alt='Plataforma A+'></a></p>
    <h3>${local.cf_distribution_name}</h3>
  </center>
</body>
</html>
HTML

  lifecycle {
    ignore_changes = all
  }
}

# CloudFront Distribution

resource "aws_cloudfront_distribution" "application_cf_distribution" {
  origin {
    domain_name = module.s3_bucket_for_application_cf_client.s3_bucket_bucket_regional_domain_name
    origin_id   = "${module.s3_bucket_for_application_cf_client.s3_bucket_id}/current"
    origin_path = "/current"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }

  enabled             = true
  wait_for_deployment = false
  is_ipv6_enabled     = false
  comment             = var.cf_distribution_name
  price_class         = "PriceClass_200"
  default_root_object = var.cf_distribution_default_root_object

  aliases = local.cf_subdomain_name

  viewer_certificate {
    cloudfront_default_certificate = false
    acm_certificate_arn = local.acm_certificate_arn
    ssl_support_method = "sni-only"
    minimum_protocol_version = "TLSv1.2_2019"
  }
  # TODO: To implement methods for Certs Creation
  
  custom_error_response {
    error_caching_min_ttl = "15"
    error_code            = "404"
    response_code         = "200"
    response_page_path    = var.cf_distribution_response_page_path
  }
  
  custom_error_response {
    error_caching_min_ttl = "15"
    error_code            = "403"
    response_code         = "200"
    response_page_path    = var.cf_distribution_response_page_path
  }

  default_cache_behavior {
    allowed_methods  = var.cf_distribution_allowed_methods
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${module.s3_bucket_for_application_cf_client.s3_bucket_id}/current"

    forwarded_values {
      query_string = false
      headers      = []

      cookies {
        forward = "none"
      }
    }

    compress               = true
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  logging_config {
    include_cookies = false
    bucket          = module.s3_bucket_for_application_cf_log.s3_bucket_bucket_regional_domain_name
    prefix          = "CloudFrontDistribution-${local.cf_distribution_name}"
  }

  tags = {
    Terraform   = true  
    Environment = local.cf_distribution_environment
    CostCenter  = "Global" 
    Project     = var.cf_distribution_name
  }

  depends_on = [ 
    module.s3_bucket_for_application_cf_client,
    module.s3_bucket_for_application_cf_log
  ]
}

# R53 records

resource "aws_route53_record" "r53_public_zone_record_cf" {
  for_each = toset(var.r53_record_name)
  zone_id  = data.aws_route53_zone.r53_hosted_zone.id
  name     = each.value
  type     = "CNAME"
  ttl      = 60
  records  = [ aws_cloudfront_distribution.application_cf_distribution.domain_name ]

  depends_on = [ 
    aws_cloudfront_distribution.application_cf_distribution,
    data.aws_route53_zone.r53_hosted_zone
  ]
}
