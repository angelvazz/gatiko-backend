output "ses_arn" {
    description = "ARN of SES service"
    value = aws_ses_email_identity.email.arn
}