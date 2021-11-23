## Tenant Settings
resource "auth0_tenant" "example_tenant" {
  friendly_name = "Example Friendly Name"
  support_email = "support@example.com"
  flags {
    enable_client_connections      = false
    enable_custom_domain_in_emails = true
  }
  default_directory = auth0_connection.exampledb.name
  depends_on = [
    auth0_connection.exampledb,
    auth0_custom_domain_verification.custom_domain_verification
  ]
}

## Applications
resource "auth0_client" "example_spa" {
  name            = "Example SPA"
  description     = "Example SPA"
  app_type        = "spa"
  oidc_conformant = true
  is_first_party  = true
  grant_types = [
    "authorization_code"
  ]
  callbacks           = var.example_spa_callback_urls
  allowed_logout_urls = var.example_spa_logout_urls
}

resource "auth0_client" "example_m2m" {
  name            = "Example M2M"
  description     = "Example M2M"
  app_type        = "non_interactive"
  oidc_conformant = true
  is_first_party  = true
  grant_types = [
    "client_credentials"
  ]
}

resource "auth0_client_grant" "example_client_grant" {
  client_id = auth0_client.example_m2m.id
  audience  = auth0_resource_server.example_api.identifier
  scope     = ["read:data", "update:data", "delete:data"]
  depends_on = [
    auth0_client.example_m2m,
    auth0_resource_server.example_api
  ]
}

resource "auth0_client" "example_m2m_auth0_api2" {
  name            = "Example M2M for Auth0 API2"
  description     = "Example M2M for Auth0 API2"
  app_type        = "non_interactive"
  oidc_conformant = true
  is_first_party  = true
  grant_types = [
    "client_credentials"
  ]
}

resource "auth0_client_grant" "example_client_grant_auth0_api2" {
  client_id = auth0_client.example_m2m_auth0_api2.id
  audience  = "https://${var.auth0_domain}/api/v2/"
  scope     = ["read:actions", "update:actions"]
  depends_on = [
    auth0_client.example_m2m_auth0_api2
  ]
}


## Connection
resource "auth0_connection" "exampledb" {
  name     = "exampledb"
  strategy = "auth0"
  options {
    requires_username = false
    password_policy   = "none"
    disable_signup    = true
  }
  enabled_clients = [
    auth0_client.example_spa.id,
    var.auth0_tf_client_id
  ]
  depends_on = [
    auth0_client.example_spa
  ]
}

## Users
resource "auth0_user" "sample_user" {
  connection_name = auth0_connection.exampledb.name
  email           = var.auth0_sample_user_email
  password        = var.auth0_sample_user_password
  user_metadata   = "{\"t_shirt_size\":\"M\"}"
  app_metadata    = "{\"role\":\"admin\"}"
  lifecycle {
    ignore_changes = [email_verified]
  }
  depends_on = [
    auth0_connection.exampledb
  ]
}

## Custom Domain
resource "auth0_custom_domain" "custom_domain" {
  domain = var.auth0_custom_domain
  type   = "auth0_managed_certs"
}

resource "auth0_custom_domain_verification" "custom_domain_verification" {
  custom_domain_id = auth0_custom_domain.custom_domain.id
  timeouts { create = "10m" }
  depends_on = [
    aws_route53_record.custom_domain_cname
  ]
}

## Branding

# Login Page Template
data "local_file" "login_html" {
  filename = "../files/page_templates/login.html"
}

# New UL Branding Cusotmization
resource "auth0_branding" "brand" {
  logo_url    = var.auth0_ulp_logo_url
  favicon_url = var.auth0_ulp_favicon_url
  colors {
    primary         = "#0059d6"
    page_background = "#000000"
  }
  universal_login {
    body = data.local_file.login_html.content
  }
  font {
    url = "https://test.drkuhxk159ske.amplifyapp.com/static/media/UntitledSans-Regular.1e012fa4.woff"
  }
  depends_on = [
    auth0_custom_domain_verification.custom_domain_verification
  ]
}

## New UL Prompt Customization
resource "auth0_prompt" "prompt" {
  universal_login_experience = "new"
  identifier_first           = false
  lifecycle {
    ignore_changes = [identifier_first]
  }
}

## Email Provider
resource "auth0_email" "mailtrap_provider" {
  name                 = "smtp"
  enabled              = true
  default_from_address = "sender@example.com"
  credentials {
    smtp_host = "smtp.mailtrap.io"
    smtp_port = 2525
    smtp_user = var.mailtrap_smtp_user
    smtp_pass = var.mailtrap_smtp_pass
  }
}

## Email Templates
data "local_file" "email_template_change_password" {
  filename = "../files/email_templates/change_password.html"
}

resource "auth0_email_template" "email_template_change_password" {
  template                = "change_password"
  body                    = data.local_file.email_template_change_password.content
  from                    = "sender@example.com"
  result_url              = "https://example.com/about"
  subject                 = "Your Change Password Request"
  syntax                  = "liquid"
  url_lifetime_in_seconds = 432000
  enabled                 = true
  depends_on              = [auth0_email.mailtrap_provider]
}

## Actions
data "local_file" "action_post_login_decorate_idtoken" {
  filename = "../files/actions/post_login_decorate_idtoken.js"
}

resource "auth0_action" "action_post_login_decorate_idtoken" {
  name = "Decorate ID Token"
  supported_triggers {
    id      = "post-login"
    version = "v2"
  }
  code = data.local_file.action_post_login_decorate_idtoken.content
}

## Resource Server (API)
resource "auth0_resource_server" "example_api" {
  name        = "Example API"
  identifier  = "https://api.example.com"
  signing_alg = "RS256"
  scopes {
    value       = "read:data"
    description = "Read your data"
  }
  scopes {
    value       = "update:data"
    description = "Update your data"
  }
  scopes {
    value       = "delete:data"
    description = "Delete your data"
  }
  allow_offline_access                            = true
  token_lifetime                                  = 8600
  skip_consent_for_verifiable_first_party_clients = true
}

## Log Stream - AWS Eventbridge
resource "auth0_log_stream" "eventbridge" {
  name   = "AWS Eventbridge"
  type   = "eventbridge"
  status = "active"
  sink {
    aws_region     = var.aws_region
    aws_account_id = var.aws_account_id
  }
}
