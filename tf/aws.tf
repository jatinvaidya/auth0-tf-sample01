resource "aws_route53_record" "custom_domain_cname" {
  zone_id = var.aws_r53_hosted_zone_id
  name    = var.aws_r53_cname_record_name
  type    = "CNAME"
  ttl     = "5"
  records = ["${auth0_custom_domain.custom_domain.verification[0].methods[0].record}."]
  depends_on = [
    auth0_custom_domain.custom_domain
  ]
}

resource "aws_cloudwatch_log_group" "auth0_logs" {
  name              = "/aws/events/${var.aws_cloudwatch_log_group_name}"
  retention_in_days = 3
}

resource "aws_cloudwatch_event_rule" "event_rule" {
  name           = "auth0_events_rule"
  description    = "Capture Auth0 events"
  event_bus_name = auth0_log_stream.eventbridge.sink[0].aws_partner_event_source

  event_pattern = <<EOF
{
  "account": [
    "${var.aws_account_id}"
  ],
  "detail": {
    "data": {
      "type": ["sapi"],
      "description": [
        "Rotate a client secret",
        "Delete a client",
        "Rotate the Application Signing Key",
        "Revoke an Application Signing Key by its key id"
      ]
    }
  }
}
EOF
  depends_on = [
    auth0_log_stream.eventbridge
  ]
}

resource "aws_cloudwatch_event_target" "cloudwatch_event_target" {
  arn            = aws_cloudwatch_log_group.auth0_logs.arn
  rule           = aws_cloudwatch_event_rule.event_rule.name
  event_bus_name = auth0_log_stream.eventbridge.sink[0].aws_partner_event_source
  depends_on = [
    auth0_log_stream.eventbridge
  ]
}

resource "aws_iam_role" "lambda_exec" {
  name               = "renew_m2m_token_lambda_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_lambda_function" "renew_m2m_token" {
  function_name = "renew_m2m_token"

  s3_bucket = var.aws_lambda_s3_bucket
  s3_key    = var.aws_lambda_s3_key

  handler = var.aws_lambda_handler
  runtime = "nodejs14.x"

  role    = aws_iam_role.lambda_exec.arn
  timeout = 20

  environment {
    variables = {
      REGION                     = var.aws_region
      AUTH0_DOMAIN               = var.auth0_domain
      AUTH0_CLIENT_ID            = auth0_client.example_m2m.id
      AUTH0_LAMBDA_CLIENT_SECRET = auth0_client.example_m2m.client_secret
      NODE_OPTIONS               = "--enable-source-maps"
    }
  }

  depends_on = [
    auth0_client_grant.example_client_grant,
    aws_iam_role.lambda_exec
  ]
}
