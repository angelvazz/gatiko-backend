output "user_pool_id" {
    description = "Id of the user pool"
    value = aws_cognito_user_pool.gatikopool.id
}