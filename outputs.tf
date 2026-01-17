output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.qdrant_vpc.id
}

output "load_balancer_dns" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.qdrant_alb.dns_name
}

output "load_balancer_url" {
  description = "Full URL to access Qdrant API"
  value       = "http://${aws_lb.qdrant_alb.dns_name}"
}

output "api_endpoint" {
  description = "Qdrant API endpoint"
  value       = "http://${aws_lb.qdrant_alb.dns_name}:6333"
}

output "grpc_endpoint" {
  description = "Qdrant gRPC endpoint"
  value       = "${aws_lb.qdrant_alb.dns_name}:6334"
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.qdrant.name
}

output "security_group_id" {
  description = "Security Group ID for Qdrant instances"
  value       = aws_security_group.qdrant_instances.id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = aws_subnet.qdrant_private[*].id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.qdrant_public[*].id
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = aws_lb_target_group.qdrant_api.arn
}
