# ===============================
# IAM USER SETUP
# ===============================

# Create IAM user
resource "aws_iam_user" "user" {
  name          = var.iam_user_name
  path          = "/"
  force_destroy = true
}

# Attach AWS managed AdministratorAccess policy
resource "aws_iam_user_policy_attachment" "s3_readonly" {
  user       = aws_iam_user.user.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Custom inline policy for EC2 read-only actions
data "aws_iam_policy_document" "custom" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeTags",
      "ec2:DescribeVolumes",
      "ec2:DescribeSnapshots"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_user_policy" "custom_policy" {
  name   = "${var.iam_user_name}-ec2-describe"
  user   = aws_iam_user.user.name
  policy = data.aws_iam_policy_document.custom.json
}

# Access key for programmatic access
resource "aws_iam_access_key" "user_key" {
  user = aws_iam_user.user.name
}

# ===============================
# S3 BUCKET SETUP
# ===============================

resource "aws_s3_bucket" "bucket" {
  bucket        = "my-demo-s3bucket-${var.iam_user_name}-${random_id.suffix.hex}"
  force_destroy = true
}

# Random ID for uniqueness
resource "random_id" "suffix" {
  byte_length = 4
}

# Create an inline bucket policy to grant this IAM user full access to this bucket
data "aws_iam_policy_document" "s3_bucket_access" {
  statement {
    sid    = "AllowUserFullAccessToBucket"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [aws_iam_user.user.arn]
    }

    actions = [
      "s3:*"
    ]

    resources = [
      aws_s3_bucket.bucket.arn,
      "${aws_s3_bucket.bucket.arn}/*"
    ]
  }
}

# Attach that policy to the bucket
resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.bucket.id
  policy = data.aws_iam_policy_document.s3_bucket_access.json
}

# ===============================
# OUTPUTS
# ===============================

output "iam_user_name" {
  value = aws_iam_user.user.name
}

output "access_key_id" {
  value = aws_iam_access_key.user_key.id
}

output "secret_access_key" {
  value     = aws_iam_access_key.user_key.secret
  sensitive = true
}

output "bucket_name" {
  value = aws_s3_bucket.bucket.bucket
}
