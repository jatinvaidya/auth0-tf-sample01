variable "env" {
  type        = string
  description = "environment code"
}

variable "auth0_domain" {
  type        = string
  description = "auth0 domain"
}

variable "auth0_tf_client_id" {
  type        = string
  description = "Auth0 TF provider client_id"
}

variable "auth0_tf_client_secret" {
  type        = string
  description = "Auth0 TF provider client_secret"
  sensitive   = true
}

variable "auth0_custom_domain" {
  type        = string
  description = "Auth0 Custom Domain"
}

variable "auth0_sample_user_email" {
  type        = string
  description = "Sample user email"
  default     = "test_user01@example.com"
}

variable "auth0_sample_user_password" {
  type        = string
  description = "Sample user password"
  default     = "test_user01@example.com"
  sensitive   = true
}

variable "auth0_ulp_logo_url" {
  type        = string
  description = "Auth0 Universal Login Logo URL"
}

variable "auth0_ulp_favicon_url" {
  type        = string
  description = "Auth0 Universal Login Favicon URL"
}

variable "mailtrap_smtp_user" {
  type = string
}

variable "mailtrap_smtp_pass" {
  type      = string
  sensitive = true
}

variable "example_spa_callback_urls" {
  type = list(string)
}

variable "example_spa_logout_urls" {
  type = list(string)
}

variable "aws_region" {
  type = string
}

variable "aws_account_id" {
  type = string
}

variable "aws_cloudwatch_log_group_name" {
  type = string
}

variable "aws_r53_hosted_zone_id" {
  type = string
}

variable "aws_r53_cname_record_name" {
  type = string
}

variable "aws_lambda_s3_bucket" {
  type = string
}

variable "aws_lambda_s3_key" {
  type = string
}

variable "aws_lambda_handler" {
  type = string
}

variable "auth0_update_action_client_id" {
  type = string
}

variable "auth0_update_action_client_secret" {
  type = string
}
