output "alb_arn" {
  value = aws_lb.this.arn
}

output "alb_dns_name" {
  description = "DNS công khai để curl"
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "Hosted zone ID, dùng cho Route53 alias record"
  value       = aws_lb.this.zone_id
}

output "target_group_arn" {
  description = "ARN Target Group — gắn vào ASG qua aws_autoscaling_attachment"
  value       = aws_lb_target_group.this.arn
}

output "alb_security_group_id" {
  description = "ALB SG ID — EC2 SG sẽ allow inbound 80 từ đây"
  value       = aws_security_group.alb.id
}
