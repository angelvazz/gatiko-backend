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

