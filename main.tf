# Create dk production VPC with DNS support enabled
resource "aws_vpc" "dk_production_network" {
  cidr_block           = var.dk_vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "dk-production-vpc"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# Attach Internet Gateway to allow public internet access
resource "aws_internet_gateway" "dk_production_igw" {
  vpc_id = aws_vpc.dk_production_network.id

  tags = {
    Name        = "dk-production-igw"
    Environment = "production"
  }
}

# Fetch available Availability Zones dynamically
data "aws_availability_zones" "dk_available_zones" {
  state = "available"
}

# Create Public Subnet in Availability Zone A
resource "aws_subnet" "dk_public_subnet_az_a" {
  vpc_id                  = aws_vpc.dk_production_network.id
  cidr_block              = var.dk_public_subnet_az_a_cidr
  availability_zone       = data.aws_availability_zones.dk_available_zones.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "dk-public-subnet-az-a"
  }
}

# Create Public Subnet in Availability Zone B
resource "aws_subnet" "dk_public_subnet_az_b" {
  vpc_id                  = aws_vpc.dk_production_network.id
  cidr_block              = var.dk_public_subnet_az_b_cidr
  availability_zone       = data.aws_availability_zones.dk_available_zones.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "dk-public-subnet-az-b"
  }
}

# Create Private Subnet in Availability Zone A
resource "aws_subnet" "dk_private_subnet_az_a" {
  vpc_id            = aws_vpc.dk_production_network.id
  cidr_block        = var.dk_private_subnet_az_a_cidr
  availability_zone = data.aws_availability_zones.dk_available_zones.names[0]

  tags = {
    Name = "dk-private-subnet-az-a"
  }
}

# Create Private Subnet in Availability Zone B
resource "aws_subnet" "dk_private_subnet_az_b" {
  vpc_id            = aws_vpc.dk_production_network.id
  cidr_block        = var.dk_private_subnet_az_b_cidr
  availability_zone = data.aws_availability_zones.dk_available_zones.names[1]

  tags = {
    Name = "dk-private-subnet-az-b"
  }
}

# Create Route Table for Public Subnets
resource "aws_route_table" "dk_public_route_table" {
  vpc_id = aws_vpc.dk_production_network.id

  tags = {
    Name = "dk-public-route-table"
  }
}

# Add default route to Internet Gateway for public internet access
resource "aws_route" "dk_public_internet_route" {
  route_table_id         = aws_route_table.dk_public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.dk_production_igw.id
}

# Associate Public Subnet AZ-A with Public Route Table
resource "aws_route_table_association" "dk_public_subnet_az_a_association" {
  subnet_id      = aws_subnet.dk_public_subnet_az_a.id
  route_table_id = aws_route_table.dk_public_route_table.id
}

# Associate Public Subnet AZ-B with Public Route Table
resource "aws_route_table_association" "dk_public_subnet_az_b_association" {
  subnet_id      = aws_subnet.dk_public_subnet_az_b.id
  route_table_id = aws_route_table.dk_public_route_table.id
}

# Create Private Route Table for AZ-A
resource "aws_route_table" "dk_private_route_table_az_a" {
  vpc_id = aws_vpc.dk_production_network.id

  tags = {
    Name = "dk-private-route-table-az-a"
  }
}

# Create Private Route Table for AZ-B
resource "aws_route_table" "dk_private_route_table_az_b" {
  vpc_id = aws_vpc.dk_production_network.id

  tags = {
    Name = "dk-private-route-table-az-b"
  }
}

# Associate Private Subnet AZ-A with its Private Route Table
resource "aws_route_table_association" "dk_private_subnet_az_a_association" {
  subnet_id      = aws_subnet.dk_private_subnet_az_a.id
  route_table_id = aws_route_table.dk_private_route_table_az_a.id
}

# Associate Private Subnet AZ-B with its Private Route Table
resource "aws_route_table_association" "dk_private_subnet_az_b_association" {
  subnet_id      = aws_subnet.dk_private_subnet_az_b.id
  route_table_id = aws_route_table.dk_private_route_table_az_b.id
}
# Allocate Elastic IP for NAT Gateway in AZ-A
resource "aws_eip" "dk_nat_eip_az_a" {
  domain = "vpc"

  tags = {
    Name = "dk-nat-eip-az-a"
  }
}
# Allocate Elastic IP for NAT Gateway in AZ-B
resource "aws_eip" "dk_nat_eip_az_b" {
  domain = "vpc"

  tags = {
    Name = "dk-nat-eip-az-b"
  }
}
# Create NAT Gateway in Public Subnet AZ-A
resource "aws_nat_gateway" "dk_nat_gateway_az_a" {
  allocation_id = aws_eip.dk_nat_eip_az_a.id
  subnet_id     = aws_subnet.dk_public_subnet_az_a.id

  tags = {
    Name = "dk-nat-gateway-az-a"
  }

  depends_on = [aws_internet_gateway.dk_production_igw]
}
# Create NAT Gateway in Public Subnet AZ-B
resource "aws_nat_gateway" "dk_nat_gateway_az_b" {
  allocation_id = aws_eip.dk_nat_eip_az_b.id
  subnet_id     = aws_subnet.dk_public_subnet_az_b.id

  tags = {
    Name = "dk-nat-gateway-az-b"
  }

  depends_on = [aws_internet_gateway.dk_production_igw]
}
# Add default route to NAT Gateway for Private Subnet AZ-A
resource "aws_route" "dk_private_nat_route_az_a" {
  route_table_id         = aws_route_table.dk_private_route_table_az_a.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.dk_nat_gateway_az_a.id
}
# Add default route to NAT Gateway for Private Subnet AZ-B
resource "aws_route" "dk_private_nat_route_az_b" {
  route_table_id         = aws_route_table.dk_private_route_table_az_b.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.dk_nat_gateway_az_b.id
}
# Security Group for Application Load Balancer
resource "aws_security_group" "dk_alb_security_group" {
  name        = "dk-alb-security-group"
  description = "Allow HTTP and HTTPS from internet"
  vpc_id      = aws_vpc.dk_production_network.id

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "dk-alb-security-group"
  }
}

# Security Group for Application EC2 Instances
resource "aws_security_group" "dk_ec2_security_group" {
  name        = "dk-ec2-security-group"
  description = "Allow traffic only from ALB"
  vpc_id      = aws_vpc.dk_production_network.id

  ingress {
    description     = "Allow HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.dk_alb_security_group.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "dk-ec2-security-group"
  }
}
# Security Group for RDS Database
resource "aws_security_group" "dk_rds_security_group" {
  name        = "dk-rds-security-group"
  description = "Allow MySQL access only from EC2"
  vpc_id      = aws_vpc.dk_production_network.id

  ingress {
    description     = "Allow MySQL from EC2"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.dk_ec2_security_group.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "dk-rds-security-group"
  }
}
# Create Application Load Balancer in public subnets
resource "aws_lb" "dk_application_load_balancer" {
  name               = "dk-application-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.dk_alb_security_group.id]
  subnets = [
    aws_subnet.dk_public_subnet_az_a.id,
    aws_subnet.dk_public_subnet_az_b.id
  ]

  tags = {
    Name = "dk-application-alb"
  }
}

# Create Target Group for EC2 instances
resource "aws_lb_target_group" "dk_application_target_group" {
  name     = "dk-application-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.dk_production_network.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = {
    Name = "dk-application-target-group"
  }
}
# Create HTTP listener for ALB
resource "aws_lb_listener" "dk_http_listener" {
  load_balancer_arn = aws_lb.dk_application_load_balancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.dk_application_target_group.arn
  }
}
# Fetch latest Amazon Linux 2023 AMI
data "aws_ami" "dk_amazon_linux_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}
# Launch Template for EC2 instances in private subnets
resource "aws_launch_template" "dk_application_launch_template" {
  name_prefix   = "dk-application-launch-template"
  image_id      = data.aws_ami.dk_amazon_linux_ami.id
  instance_type = "t2.micro"

  vpc_security_group_ids = [
    aws_security_group.dk_ec2_security_group.id
  ]

  user_data = base64encode(<<EOF
#!/bin/bash
dnf update -y
dnf install -y httpd
systemctl enable httpd
systemctl start httpd
echo "Welcome to DK Production App - Amazon Linux 2023" > /var/www/html/index.html
EOF
  )

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "dk-application-ec2"
    }
  }
}

# Auto Scaling Group across private subnets
resource "aws_autoscaling_group" "dk_application_auto_scaling_group" {
  name             = "dk-application-asg"
  desired_capacity = 2
  min_size         = 2
  max_size         = 4

  vpc_zone_identifier = [
    aws_subnet.dk_private_subnet_az_a.id,
    aws_subnet.dk_private_subnet_az_b.id
  ]

  target_group_arns = [
    aws_lb_target_group.dk_application_target_group.arn
  ]

  launch_template {
    id      = aws_launch_template.dk_application_launch_template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "dk-application-asg-instance"
    propagate_at_launch = true
  }
}
# Create DB Subnet Group using private subnets
resource "aws_db_subnet_group" "dk_database_subnet_group" {
  name = "dk-database-subnet-group"

  subnet_ids = [
    aws_subnet.dk_private_subnet_az_a.id,
    aws_subnet.dk_private_subnet_az_b.id
  ]

  tags = {
    Name = "dk-database-subnet-group"
  }
}

# Create Multi-AZ MySQL RDS instance
resource "aws_db_instance" "dk_production_database" {
  identifier              = "dk-production-mysql-db"
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  username                = var.dk_db_username
  password                = var.dk_db_password
  db_subnet_group_name    = aws_db_subnet_group.dk_database_subnet_group.name
  vpc_security_group_ids  = [aws_security_group.dk_rds_security_group.id]
  multi_az                = true
  skip_final_snapshot     = true
  publicly_accessible     = false
  backup_retention_period = 7

  tags = {
    Name = "dk-production-mysql-db"
  }
}
# Create S3 bucket for Terraform remote state
resource "aws_s3_bucket" "dk_tf_state_bucket" {
  bucket = "dk-tf-state-bucket-ha-prod"

  tags = {
    Name        = "dk-tf-state-bucket-ha-prod"
    Environment = "production"
  }
}
# Enable versioning for Terraform state safety
resource "aws_s3_bucket_versioning" "dk_tf_state_versioning" {
  bucket = aws_s3_bucket.dk_tf_state_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}
# Block all public access to state bucket
resource "aws_s3_bucket_public_access_block" "dk_tf_state_public_block" {
  bucket = aws_s3_bucket.dk_tf_state_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
# Create DynamoDB table for Terraform state locking
resource "aws_dynamodb_table" "dk_terraform_state_lock_table" {
  name         = "dk-tf-state-lock-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "dk-tf-state-lock-table"
  }
}

