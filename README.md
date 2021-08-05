# A+ CloudFront Distribution solution

Plataforma A+ terraform modude for create a CloudFront Distribution.

## Example Usage

Command line:

    ~ terraform init
    ~ terraform plan \
        --var 'default_region=us-east-1' \
        --var 'cf_distribution_name=Project1' \
        --var 'r53_hosted_zone_id=Z02086222OEQ4V7Y7UH40' \
        --var 'r53_record_name=["www", "www1", "backoffice"]' \
        --var 'iam_user_name_to_attatch_deploy_policy=deploymentbot'
    ~ terraform apply \
        --var 'default_region=us-east-1' \
        --var 'cf_distribution_name=project-name' \
        --var 'r53_hosted_zone_id=Z02086222OEQ4V7Y7UH40' \
        --var 'r53_record_name=["www", "www1", "backoffice"]' \
        --var 'iam_user_name_to_attatch_deploy_policy=deploymentbot'

Module:

    module "cf_module" {
      source  = "terraform-aws-modules/s3-bucket/aws"
      # insert the 5 required variables here
    }

## Arguments Reference

| Name | Type | Default | Required | Description |
|------|------|---------|:--------:|-------------|
| acm_certificate_domain | `string` | `null` | no | (Optional) Sets a certificate domain for distribution Required if 'create_cf_certificate_arn' is defined to '`false`'. Default: `null`. |
| cf_distribution_allowed_methods | `list(string)` | ["HEAD", "GET"] | no | (Optional) Allowed methods for distribution. Default: ['HEAD', 'GET']. |
| cf_distribution_default_root_object | `string` | index.html | no | (Optional) Sets a default root objects for the distribution. Default: 'index.html'. |
| cf_distribution_environment | `string` | develop | no | (Optional) Defines a environment label. Default: `null`. |
| cf_distribution_name | `string` | `none` | yes | A name for distribution. Required. |
| cf_distribution_response_page_path | `string` | /index.html | no | (Optional) Default page path to main alternatives error pages, based in react and Angular behaviors. Default: '/index.html'. |
| cf_distribution_s3_bucket_arn | `string` | `null` | no | (Optional) Sets a bucket arn to use as source for distribution. Required if 'create_cf_distribution_s3_bucket' is `false`. Default: `null`. |
| cf_distribution_tags | `map(any)` | ({"Provisioner" = "Terraform"}) | no | (Optional) A `map()` structure of keys/values. |
| create_acm_certificate | `string` | `false` | no | (Optional) Set to `true` if want to create a certificate on AWS CMS. Default: `false`. |
| create_cf_distribution | `true` | `bool` | no | (Optional) Set to `false` if don't need to create a CloudFront Distribution. Default: `true`. |
| create_cf_distribution_s3_bucket | `string` | `true` | no | (Optional) Defines if the modules creates a bucket for distribution. Default: `true`. |
| default_region | `string` | us-east-1 | yes | Default AWS region. |
| iam_user_name_to_attatch_deploy_policy" | `string` | `null` | no | (Optional) A IAM user name to attatch the deploy policy. Default: `null`. |
| r53_hosted_zone_id | `string` | `none` | yes | Hosted zone ID for publish the distribution. Required if 'create_cf_certificate_arn' is `true` and to create distribution. |
| r53_record_name | `list(string)` | `none` | yes | A subdomain prefix to use in which zone specified in 'r53_hosted_zone_id' to address the distribution. Default: []. |
