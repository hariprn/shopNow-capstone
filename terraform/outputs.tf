output "vpc_id" {
  description = "ID of the ShopNow VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id
  ]
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]
}

output "availability_zones" {
  description = "Availability Zones used by ShopNow"
  value = [
    aws_subnet.public_a.availability_zone,
    aws_subnet.public_b.availability_zone
  ]
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = aws_nat_gateway.main.id
}

output "ecr_frontend_repository_url" {
  value = aws_ecr_repository.frontend.repository_url
}

output "ecr_backend_repository_url" {
  value = aws_ecr_repository.backend.repository_url
}

output "ecr_admin_repository_url" {
  value = aws_ecr_repository.admin.repository_url
}

output "eks_cluster_name" {
  value = aws_eks_cluster.main.name
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.main.endpoint
}

output "eks_cluster_arn" {
  value = aws_eks_cluster.main.arn
}

output "jenkins_instance_id" {
  description = "Instance ID of the ShopNow Jenkins server"
  value       = aws_instance.jenkins.id
}

output "jenkins_public_ip" {
  description = "Public IP address of the ShopNow Jenkins server"
  value       = aws_instance.jenkins.public_ip
}

output "jenkins_public_dns" {
  description = "Public DNS name of the ShopNow Jenkins server"
  value       = aws_instance.jenkins.public_dns
}
