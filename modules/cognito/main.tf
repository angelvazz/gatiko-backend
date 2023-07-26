resource "aws_cognito_user_pool" "gatikopool" {
  name = "gatikopool"
  auto_verified_attributes = ["email"]
  mfa_configuration = "OFF"


  admin_create_user_config {
    allow_admin_create_user_only = false
  }

  password_policy {
    minimum_length    = 6
    require_lowercase = false
    require_numbers   = false
    require_symbols   = false
    require_uppercase = false
  }

  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    name                     = "email"
    required                 = true

    string_attribute_constraints {
      min_length = 5
      max_length = 255
    }
  }

  verification_message_template {
    default_email_option  = "CONFIRM_WITH_LINK"
    email_message_by_link = "{##Click Here##} para verificar tu correo electrónico"
    email_subject_by_link = "Verificación de cuenta"
  }

  email_configuration {
    email_sending_account = "DEVELOPER"
    source_arn = var.ses_arn
  }

  lifecycle {
    create_before_destroy = true
  }

  lambda_config {
    custom_message = var.email_confirmation_arn
  }
}

resource "aws_cognito_user_pool_client" "client" {
  name = "mypoolclient"

  user_pool_id = aws_cognito_user_pool.gatikopool.id

  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  generate_secret = false
}

resource "aws_cognito_user_pool_domain" "domain" {
  domain       = "mypool-domain"
  user_pool_id = aws_cognito_user_pool.gatikopool.id
}

# Política unificada para el permiso de invocar el Lambda
resource "aws_iam_policy" "cognito_lambda_invocation_policy" {
  name = "cognito-lambda-invocation-policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = [
          "lambda:InvokeFunction",
          "ses:SendEmail",
          "ses:SendRawEmail"
        ]
        Effect   = "Allow",
        Resource = [
          "${var.email_confirmation_arn}"
        ]
      }
    ]
  })
}

# Rol unificado para el permiso de invocar el Lambda
resource "aws_iam_role" "cognito_lambda_invocation_role" {
  name               = "cognito-lambda-invocation-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "cognito-idp.amazonaws.com"
        }
      }
    ]
  })
}

# Adjuntar la política unificada al rol unificado
resource "aws_iam_role_policy_attachment" "cognito_lambda_invocation_permission" {
  policy_arn = aws_iam_policy.cognito_lambda_invocation_policy.arn
  role       = aws_iam_role.cognito_lambda_invocation_role.name
}
