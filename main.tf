provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "Qdrant-HA"
      ManagedBy   = "Terraform"
      Environment = var.environment
    }
  }
}

# VPC and Networking
resource "aws_vpc" "qdrant_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_internet_gateway" "qdrant_igw" {
  vpc_id = aws_vpc.qdrant_vpc.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Public Subnets across multiple AZs
resource "aws_subnet" "qdrant_public" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.qdrant_vpc.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone = var.availability_zones[count.index]

  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet-${count.index + 1}"
    Type = "Public"
  }
}

# Private Subnets for Qdrant instances
resource "aws_subnet" "qdrant_private" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.qdrant_vpc.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${var.project_name}-private-subnet-${count.index + 1}"
    Type = "Private"
  }
}

# Route Table for Public Subnets
resource "aws_route_table" "qdrant_public" {
  vpc_id = aws_vpc.qdrant_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.qdrant_igw.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table_association" "qdrant_public" {
  count          = length(aws_subnet.qdrant_public)
  subnet_id      = aws_subnet.qdrant_public[count.index].id
  route_table_id = aws_route_table.qdrant_public.id
}

# NAT Gateway for Private Subnets (using single NAT for cost optimization)
resource "aws_eip" "qdrant_nat" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-nat-eip"
  }
}

resource "aws_nat_gateway" "qdrant_nat" {
  allocation_id = aws_eip.qdrant_nat.id
  subnet_id     = aws_subnet.qdrant_public[0].id

  tags = {
    Name = "${var.project_name}-nat"
  }

  depends_on = [aws_internet_gateway.qdrant_igw]
}

# Route Table for Private Subnets
resource "aws_route_table" "qdrant_private" {
  vpc_id = aws_vpc.qdrant_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.qdrant_nat.id
  }

  tags = {
    Name = "${var.project_name}-private-rt"
  }
}

resource "aws_route_table_association" "qdrant_private" {
  count          = length(aws_subnet.qdrant_private)
  subnet_id      = aws_subnet.qdrant_private[count.index].id
  route_table_id = aws_route_table.qdrant_private.id
}

# Security Groups
resource "aws_security_group" "qdrant_alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Security group for Qdrant Application Load Balancer"
  vpc_id      = aws_vpc.qdrant_vpc.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
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
    Name = "${var.project_name}-alb-sg"
  }
}

resource "aws_security_group" "qdrant_instances" {
  name        = "${var.project_name}-instances-sg"
  description = "Security group for Qdrant instances"
  vpc_id      = aws_vpc.qdrant_vpc.id

  ingress {
    description     = "Qdrant API from ALB"
    from_port       = 6333
    to_port         = 6333
    protocol        = "tcp"
    security_groups = [aws_security_group.qdrant_alb.id]
  }

  ingress {
    description     = "Qdrant gRPC from ALB"
    from_port       = 6334
    to_port         = 6334
    protocol        = "tcp"
    security_groups = [aws_security_group.qdrant_alb.id]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-instances-sg"
  }
}

# Application Load Balancer
resource "aws_lb" "qdrant_alb" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.qdrant_alb.id]
  subnets            = aws_subnet.qdrant_public[*].id

  enable_deletion_protection = false

  tags = {
    Name = "${var.project_name}-alb"
  }
}

# Target Group for Qdrant API
resource "aws_lb_target_group" "qdrant_api" {
  name     = "${var.project_name}-api-tg"
  port     = 6333
  protocol = "HTTP"
  vpc_id   = aws_vpc.qdrant_vpc.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200,404"
  }

  deregistration_delay = 30

  tags = {
    Name = "${var.project_name}-api-tg"
  }
}

# ALB Listener
resource "aws_lb_listener" "qdrant_api" {
  load_balancer_arn = aws_lb.qdrant_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.qdrant_api.arn
  }
}

# Launch Template for Qdrant instances
resource "aws_launch_template" "qdrant" {
  name_prefix   = "${var.project_name}-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  key_name      = var.key_pair_name != "" ? var.key_pair_name : null

  vpc_security_group_ids = [aws_security_group.qdrant_instances.id]

  user_data = base64encode(templatefile("${path.module}/scripts/qdrant-init.sh", {
    qdrant_version = var.qdrant_version
    cluster_mode   = var.enable_cluster_mode ? "true" : "false"
  }))

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.volume_size
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = true
    }
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.qdrant.name
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.project_name}-instance"
    }
  }

  tags = {
    Name = "${var.project_name}-launch-template"
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "qdrant" {
  name                      = "${var.project_name}-asg"
  vpc_zone_identifier       = aws_subnet.qdrant_private[*].id
  target_group_arns         = [aws_lb_target_group.qdrant_api.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300

  min_size         = var.min_instances
  max_size         = var.max_instances
  desired_capacity = var.desired_instances

  launch_template {
    id      = aws_launch_template.qdrant.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-asg-instance"
    propagate_at_launch = true
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }
}

# IAM Role for Qdrant instances
resource "aws_iam_role" "qdrant" {
  name = "${var.project_name}-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-instance-role"
  }
}

resource "aws_iam_instance_profile" "qdrant" {
  name = "${var.project_name}-instance-profile"
  role = aws_iam_role.qdrant.name
}

resource "aws_iam_role_policy" "qdrant" {
  name = "${var.project_name}-instance-policy"
  role = aws_iam_role.qdrant.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeTags",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# Data source for Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
