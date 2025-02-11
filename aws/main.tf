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
  engine               = "postgres"
  engine_version       = "13"
  instance_class       = "db.t3.medium"
  allocated_storage    = 20
  username             = "artifactory"
  password             = "StrongPassword123!"  # Change or use AWS Secrets Manager
  publicly_accessible  = false
  vpc_security_group_ids = [aws_security_group.artifactory_sg.id]
  skip_final_snapshot  = true
}

#----------------------
# Application Load Balancer (ALB)
#----------------------
resource "aws_lb" "artifactory_alb" {
  name               = "artifactory-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.artifactory_sg.id]
  subnets            = ["subnet-xxxxxxxx", "subnet-yyyyyyyy"]  # Replace with actual subnet IDs
}

resource "aws_lb_target_group" "artifactory_tg" {
  name     = "artifactory-tg"
  port     = 8081
  protocol = "HTTP"
  vpc_id   = "vpc-xxxxxxxx"  # Replace with actual VPC ID
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.artifactory_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.artifactory_tg.arn
  }
}

#----------------------
# Auto Scaling Group (ASG)
#----------------------
resource "aws_launch_template" "artifactory_lt" {
  name          = "artifactory-launch-template"
  image_id      = "ami-xxxxxxxx"  # Replace with latest Amazon Linux 2 or Ubuntu AMI ID
  instance_type = "t3.medium"
  key_name      = "my-key"  # Replace with your key pair

  iam_instance_profile {
    name = aws_iam_instance_profile.artifactory_profile.name
  }

  network_interfaces {
    security_groups = [aws_security_group.artifactory_sg.id]
  }
}

resource "aws_autoscaling_group" "artifactory_asg" {
  desired_capacity     = 2
  min_size            = 1
  max_size            = 3
  vpc_zone_identifier = ["subnet-xxxxxxxx", "subnet-yyyyyyyy"]  # Replace with actual subnet IDs

  launch_template {
    id      = aws_launch_template.artifactory_lt.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.artifactory_tg.arn]
}

#----------------------
# Outputs
#----------------------
output "alb_dns_name" {
  value       = aws_lb.artifactory_alb.dns_name
  description = "DNS name of the Application Load Balancer"
}

output "rds_endpoint" {
  value       = aws_db_instance.artifactory_db.endpoint
  description = "Endpoint for the PostgreSQL RDS instance"
}

#----------------------
# Documentation
#----------------------
# This Terraform script deploys Artifactory Edge in AWS with:
# 1. An Auto Scaling Group for Artifactory Edge instances.
# 2. An Application Load Balancer (ALB) for distributing traffic.
# 3. An S3 bucket for storing artifacts.
# 4. A PostgreSQL RDS instance for metadata storage.
# 5. IAM roles for secure access to AWS resources.
# 6. Security groups to control network access.
# Modify the variables such as region, AMI ID, instance type, and subnets as needed before deployment.
