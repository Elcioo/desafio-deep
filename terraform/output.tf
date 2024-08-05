output "load_balancer_dns" {
  value       = aws_alb.this.dns_name
  description = "O dns referente ao load balaner criado"
}