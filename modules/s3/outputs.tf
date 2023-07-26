output "bucket_id" {
  description = "ID of the S3 Bucket"
  value       = aws_s3_bucket.b.id
}