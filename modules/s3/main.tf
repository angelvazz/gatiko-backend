resource "aws_iam_role" "my_role" {
  name = "my_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "s3.amazonaws.com"
        },
        Effect = "Allow",
      },
    ]
  })
}

resource "aws_s3_bucket" "b" {
  bucket_prefix = "${var.name}-"
}

data "aws_iam_policy_document" "bucket_policy" {
  statement {
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.b.arn}/*"]
    principals {
      identifiers = ["${aws_iam_role.my_role.arn}"]
      type        = "AWS"
    }
  }
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.b.id
  policy = data.aws_iam_policy_document.bucket_policy.json
}
