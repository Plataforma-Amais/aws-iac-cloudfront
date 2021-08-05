variable "acm_certificate_domain" {
  type = string
  default = null
  description = "Sets a certificate domain for distribution Required if 'create_cf_certificate_arn' is seted to 'false'. Default: null."
}
variable "cf_distribution_environment" {
  type = string
  default = "develop"
  description = "Defines a environment label. Default: null"
}
variable "cf_distribution_tags" {
  type = map(any)
  default = ({"Provisioner" = "Terraform"})
  description = "A map() structuro of keys/values."
}
variable "cf_distribution_allowed_methods" {
  type = list(string)
  default = ["HEAD", "GET"]
  description = "Allowed methods for distribution. Default: ['HEAD', 'GET']."
}
variable "cf_distribution_default_root_object" {
  type = string
  default = "index.html"
  description = "Sets a default root objects for the distribution. Default: 'index.html'."
}
variable "cf_distribution_response_page_path" {
  type = string
  default = "/index.html"
  description = "Default page path to main alternatives error pages, based in react and Angular behaviours. Defauklt: '/index.html'"
}
variable "cf_distribution_name" {
  type = string
  description = "* A name for distribution. Required."
}
variable "cf_distribution_s3_bucket_arn" {
  type = string
  default = null
  description = "Sets a bucket arn to use as source for distribution. Required if 'create_cf_distribution_s3_bucket' is false. Default: null."
}
variable "create_cf_distribution_s3_bucket" {
  type = string
  default = true
  description = "Defines if the modules creates a bucket for distribution. Default: true."
}
variable "default_region" {
  type = string
  default =  "us-east-1"
  description =  "* Default AWS region. Default: 'us-east-1'"
}
variable "iam_user_name_to_attatch_deploy_policy" {
  type = string
  default = null
  description = "(Optional) A IAM user name to attatch the deploy policy. Default: `null`."
}
variable "r53_hosted_zone_id" {
  type = string
  description = "* Hosted zone ID for publish the distribution. Required if 'create_cf_certificate_arn' is true and to create distribution."
}
variable "r53_record_name" {
  type = list(string)
  description = "* A subdomain prefix to use in wich zone specified in 'r53_hosted_zone_id' to address the distribution. Default: []."
}
variable "create_acm_certificate" {
  type = string
  default = false
  description = "Set to true if whant to create a certificate on AWS CMS. Default: false."
}
variable "create_cf_distribution" {
  default = true
  type = bool
  description = "Set to false if don`t need to create a CloudFront Distribution. Default: true."
}