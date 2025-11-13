#################################
# AWS Provider
#################################
provider "aws" {
  region = "us-east-1"
}

#################################
# VPC & Subnets (Data sources)
#################################
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

#################################
# IAM Role for RDS Secrets Manager
#################################
resource "aws_iam_role" "rds_secrets_role" {
  name = "rds-secretsmanager-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "rds.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Policy to allow RDS to read from Secrets Manager
resource "aws_iam_role_policy" "rds_secret_policy" {
  name = "rds-secretsmanager-access"
  role = aws_iam_role.rds_secrets_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = "kms:Decrypt",
        Resource = "*"
      }
    ]
  })
}

#################################
# RDS Instance (Terraform AWS RDS Module)
#################################
module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.3"

  identifier = "my-db"

  engine            = "mysql"
  instance_class    = "db.t3.micro"
  allocated_storage = 20

  db_name  = "mydatabase"
  username = "admin"

  # ✅ Enable AWS Secrets Manager for password
  manage_master_user_password = true
  manage_master_user_password_rotation = true
  master_user_password_rotation_automatically_after_days = 30

  # Required engine family + version info (for option/parameter groups)
  family               = "mysql8.0"
  engine_version    = "8.0.37"   # 👈 Full version OK here
  major_engine_version = "8.0"  

  # Networking
  create_db_subnet_group = true
  subnet_ids             = data.aws_subnets.default.ids
  vpc_security_group_ids = []

  # Misc
  skip_final_snapshot = true
  deletion_protection = false

  tags = {
    Environment = "dev"
    Project     = "rds-secrets-demo"
  }
}

#################################
# Associate IAM Role with the DB
#################################
# resource "aws_db_instance_role_association" "rds_secrets_role_assoc" {
#   db_instance_identifier = module.rds.db_instance_identifier
#   feature_name           = "S3_INTEGRATION"
#   role_arn               = aws_iam_role.rds_secrets_role.arn
# }

#################################
# Fetch info about the created RDS instance
#################################
data "aws_db_instance" "rds" {
  db_instance_identifier = module.rds.db_instance_identifier
   depends_on = [module.rds]
}

#################################
# Fetch current Secret Value (Optional)
#################################
data "aws_secretsmanager_secret_version" "rds_secret_value" {
  # Defensive check — use element() for safety in case array index differs
  secret_id = element(data.aws_db_instance.rds.master_user_secret[*].secret_arn, 0)
}

#################################
# Outputs
#################################
output "rds_endpoint" {
  value = module.rds.db_instance_endpoint
}

output "rds_identifier" {
  value = module.rds.db_instance_identifier
}

# ✅ Output ARN of the generated RDS master secret
output "rds_secret_arn" {
  value = element(data.aws_db_instance.rds.master_user_secret[*].secret_arn, 0)
}

# ⚠️ Sensitive: Outputs the actual password (hidden in console)
output "rds_master_password" {
  value     = jsondecode(data.aws_secretsmanager_secret_version.rds_secret_value.secret_string)["password"]
  sensitive = true
}

output "rds_iam_role" {
  value = aws_iam_role.rds_secrets_role.arn
}
