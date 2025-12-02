output "vpc_id" {
  description = "VPC ID"
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.network.private_subnet_ids
}

output "nat_gateway_ips" {
  description = "NAT Gateway Elastic IPs"
  value       = module.network.nat_gateway_ips
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.application.alb_dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = module.application.alb_zone_id
}

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = module.database.db_endpoint
  sensitive   = true
}

output "rds_port" {
  description = "RDS instance port"
  value       = module.database.db_port
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = module.application.autoscaling_group_name
}