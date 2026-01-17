variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project (used for resource naming)"
  type        = string
  default     = "qdrant-ha"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "instance_type" {
  description = "EC2 instance type (Free Tier: t2.micro or t3.micro)"
  type        = string
  default     = "t3.micro"
}

variable "min_instances" {
  description = "Minimum number of instances in ASG"
  type        = number
  default     = 2
}

variable "max_instances" {
  description = "Maximum number of instances in ASG"
  type        = number
  default     = 4
}

variable "desired_instances" {
  description = "Desired number of instances in ASG"
  type        = number
  default     = 2
}

variable "volume_size" {
  description = "Size of EBS volume in GB (Free Tier: up to 30GB)"
  type        = number
  default     = 20
}

variable "key_pair_name" {
  description = "Name of AWS Key Pair for SSH access (optional)"
  type        = string
  default     = ""
}

variable "qdrant_version" {
  description = "Qdrant version to install"
  type        = string
  default     = "1.7.4"
}

variable "enable_cluster_mode" {
  description = "Enable Qdrant cluster mode (requires shared storage)"
  type        = bool
  default     = false
}
