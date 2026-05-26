output "alb_dns_name" {
  description = "DNS công khai — curl http://<alb_dns_name>"
  value       = module.alb.alb_dns_name
}

output "alb_url" {
  description = "URL đầy đủ"
  value       = "http://${module.alb.alb_dns_name}"
}

output "alb_arn" {
  value = module.alb.alb_arn
}

output "target_group_arn" {
  value = module.alb.target_group_arn
}

output "alb_security_group_id" {
  value = module.alb.alb_security_group_id
}

output "test_command" {
  description = "Lệnh để test"
  value       = "curl http://${module.alb.alb_dns_name}"
}
