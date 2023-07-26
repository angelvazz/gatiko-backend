resource "aws_iam_role" "iam_for_lambda" {
  name = "${var.name}_iam_for_lambda"

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

resource "aws_lambda_function" "lambda" {
  s3_bucket     = var.bucket_id
  s3_key        = "${var.name}.zip"
  function_name = var.name
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "index.handler"
  source_code_hash = "${filesha256("${path.root}/dist-aws/${var.name}.zip")}"
  runtime = "nodejs16.x"
  timeout = 900
  memory_size = "128"
  
  depends_on = [
    aws_s3_object.object
  ]

  environment {
    variables = {
      USER_POOL_ID = "us-east-1_7cpltWom7"
    }
  }
}

resource "aws_iam_policy" "lambda_permissions" {
  name        = "lambda-permissions-policy-${var.name}"
  path        = "/"
  description = "IAM policy for lambda permissions in ${var.name}"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "ses:SendEmail",
          "ses:SendRawEmail",
          "cognito-idp:AdminCreateUser",
          "cognito-idp:AdminSetUserPassword",
          "cognito-idp:AdminUpdateUserAttributes",
          "cognito-idp:SignUp",
          "lambda:InvokeFunction",
        ],
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect   = "Allow",
        Action   = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ],
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = [
          "cognito-idp:AdminCreateUser",
          "cognito-idp:AdminSetUserPassword",
          "cognito-idp:AdminUpdateUserAttributes"
        ],
         Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ],
        Resource = var.table_arn_dynamodb
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "lambda_permissions" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_permissions.arn
}

resource "aws_s3_object" "object" {
  bucket = var.bucket_id
  key    = "${var.name}.zip"
  source = "${path.root}/dist-aws/${var.name}.zip"
  etag   = filemd5("${path.root}/dist-aws/${var.name}.zip")
}


resource "aws_lambda_permission" "allow_cognito" {
  statement_id  = "AllowExecutionFromCognito"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = "arn:aws:cognito-idp:us-east-1:818297291261:userpool/us-east-1_7cpltWom7"
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
