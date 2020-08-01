### Printing ALB's DNS address
output "mohi_alb_dns" {
  value = aws_alb.mohi_alb.dns_name
}