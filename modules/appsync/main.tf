resource "aws_appsync_graphql_api" "api" {
  name                = "BlogApi"
  schema              = file("${path.root}/src/graphql/blogpost.graphql")
  authentication_type = "API_KEY"
}

resource "aws_appsync_api_key" "api_key" {
  api_id = aws_appsync_graphql_api.api.id
}

resource "aws_iam_role" "appsync_exec_role" {
  name = "appsync_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "appsync.amazonaws.com"
        },
        Effect = "Allow"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "appsync_exec_role_policy_attach" {
  role       = aws_iam_role.appsync_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppSyncPushToCloudWatchLogs"
}

resource "aws_appsync_datasource" "lambda_datasource" {
  api_id = aws_appsync_graphql_api.api.id
  name   = "LambdaDatasource"
  type   = "AWS_LAMBDA"
  service_role_arn = aws_iam_role.appsync_exec_role.arn

  lambda_config {
    function_arn    = var.lambda_arn
  }
}

resource "aws_appsync_resolver" "mutation_create_post_resolver" {
  api_id      = aws_appsync_graphql_api.api.id
  type        = "Mutation"
  field       = "createPost"
  data_source = aws_appsync_datasource.lambda_datasource.name

  request_template  = file("${path.root}/src/vtl/posts/request.vtl")
  response_template = file("${path.root}/src/vtl/posts/response.vtl")
}

resource "aws_appsync_resolver" "mutation_update_post_resolver" {
  api_id      = aws_appsync_graphql_api.api.id
  type        = "Mutation"
  field       = "updatePost"
  data_source = aws_appsync_datasource.lambda_datasource.name

  request_template  = file("${path.root}/src/vtl/posts/request.vtl")
  response_template = file("${path.root}/src/vtl/posts/response.vtl")
}

resource "aws_appsync_resolver" "mutation_deletePost_post_resolver" {
  api_id      = aws_appsync_graphql_api.api.id
  type        = "Mutation"
  field       = "deletePost"
  data_source = aws_appsync_datasource.lambda_datasource.name

  request_template  = file("${path.root}/src/vtl/posts/request.vtl")
  response_template = file("${path.root}/src/vtl/posts/response.vtl")
}

resource "aws_appsync_resolver" "query_list_posts_resolver" {
  api_id      = aws_appsync_graphql_api.api.id
  type        = "Query"
  field       = "listPosts"
  data_source = aws_appsync_datasource.lambda_datasource.name

  request_template  = file("${path.root}/src/vtl/posts/request.vtl")
  response_template = file("${path.root}/src/vtl/posts/response.vtl")
}

resource "aws_iam_policy" "allow_lambda_invoke" {
  name        = "AllowLambdaInvoke"
  description = "Allows AppSync to invoke Lambda functions"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "lambda:InvokeFunction"
        ],
        Effect   = "Allow",
        Resource = var.lambda_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_lambda_invoke_policy" {
  role       = aws_iam_role.appsync_exec_role.name
  policy_arn = aws_iam_policy.allow_lambda_invoke.arn
}

resource "aws_iam_role" "appsync_unauth_role" {
  name = "appsync_unauth_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Principal = {
          Federated = "cognito-identity.amazonaws.com"
        },
        Effect = "Allow",
        Condition = {
          "StringEquals": {
            "cognito-identity.amazonaws.com:aud": aws_cognito_identity_pool.main.id
          },
          "ForAnyValue:StringLike": {
            "cognito-identity.amazonaws.com:amr": "unauthenticated"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "appsync_unauth_policy" {
  name = "appsync_unauth_policy"
  role = aws_iam_role.appsync_unauth_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "appsync:GraphQL"
        ],
        Resource = [
          "${aws_appsync_graphql_api.api.arn}/types/Query/*"
        ]
      }
    ]
  })
}

resource "aws_cognito_identity_pool" "main" {
  identity_pool_name               = "my_identity_pool"
  allow_unauthenticated_identities = true

  cognito_identity_providers {
    client_id = "262ggkf4i941h0o80m85a7f33i"
    provider_name = "cognito-idp.us-east-1.amazonaws.com/us-east-1_7cpltWom7"
  }
}

resource "aws_cognito_identity_pool_roles_attachment" "main" {
  identity_pool_id = aws_cognito_identity_pool.main.id

  roles = {
    "unauthenticated" = aws_iam_role.appsync_unauth_role.arn
  }
}
