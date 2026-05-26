output "db_endpoint" {
  value = module.database.db_endpoint
}

output "db_host" {
  value = module.database.db_host
}

output "db_security_group_id" {
  value = module.database.db_security_group_id
}

output "secret_arn" {
  description = "ARN secret chứa credentials DB"
  value       = module.database.secret_arn
}

output "secret_name" {
  value = module.database.secret_name
}
