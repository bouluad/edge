provider "aws" {
  region = "us-east-1"  # Change to your preferred region
}

#----------------------
# S3 Bucket for Storage
#----------------------
resource "aws_s3_bucket" "artifactory" {
  bucket = "artifactory-edge-storage"
  acl    = "private"
}

# IAM Policy for EC2 to Access S3
resource "aws_iam_role" "artifactory_role" {
  name = "artifactory-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Action": "sts:AssumeRole",
    "Principal": {"Service": "ec2.amazonaws.com"},
    "Effect": "Allow",
    "Sid": ""
  }]
}
EOF
}

resource "aws_iam_role_policy_attachment" "s3_attach" {
  role       = aws_iam_role.artifactory_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_instance_profile" "artifactory_profile" {
  name = "artifactory-profile"
  role = aws_iam_role.artifactory_role.name
}

#----------------------
# Security Groups
#----------------------
resource "aws_security_group" "artifactory_sg" {
  name        = "artifactory-sg"
  description = "Allow traffic for Artifactory"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Restrict in production
  }

  ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]  # Allow only internal VPC access
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#----------------------
# PostgreSQL RDS
#----------------------
resource "aws_db_instance" "artifactory_db" {
  identifier           = "artifactory-db"
  engine              = "postgres"
  engine_version      = "13"
  instance_class      = "db.t3.medium"
  allocated_storage   = 20
  username            = "artifactory"
  password            = "StrongPassword123!"  # Change or use AWS Secrets Manager
  publicly_accessible = false
  vpc_security_group_ids = [aws_security_group.artifactory_sg.id]
  skip_final_snapshot = true
}

#----------------------
# EC2 Instance for Artifactory Edge
#----------------------
resource "aws_instance" "artifactory" {
  ami                    = "ami-12345678"  # Change to latest Amazon Linux 2 or Ubuntu AMI
  instance_type          = "t3.medium"
  iam_instance_profile   = aws_iam_instance_profile.artifactory_profile.name
  security_groups        = [aws_security_group.artifactory_sg.name]
  key_name               = "my-key"  # Replace with your key pair
}

#----------------------
# Outputs
#----------------------
output "ec2_public_ip" {
  value = aws_instance.artifactory.public_ip
  description = "Public IP address of the Artifactory Edge EC2 instance"
}

output "rds_endpoint" {
  value = aws_db_instance.artifactory_db.endpoint
  description = "Endpoint for the PostgreSQL RDS instance"
}

#----------------------
# Documentation
#----------------------
# This Terraform script deploys Artifactory Edge in AWS with:
# 1. An EC2 instance for running Artifactory Edge.
# 2. An S3 bucket for storing artifacts.
# 3. A PostgreSQL RDS instance for metadata storage.
# 4. IAM roles for secure access to AWS resources.
# 5. Security groups to control network access.
# Modify the variables such as region, AMI ID, and instance type as needed before deployment.
