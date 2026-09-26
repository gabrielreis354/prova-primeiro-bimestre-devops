output "endpoint" {
  description = "Endpoint do RDS (host:porta)"
  value       = aws_db_instance.this.endpoint
}

output "address" {
  description = "Hostname do RDS (usado como DB_HOST da API)"
  value       = aws_db_instance.this.address
}

output "db_name" {
  value = aws_db_instance.this.db_name
}

output "db_username" {
  value = aws_db_instance.this.username
}
