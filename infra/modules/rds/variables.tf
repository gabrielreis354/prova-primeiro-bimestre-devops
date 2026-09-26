variable "name" {
  description = "Prefixo/identificador da instância"
  type        = string
}

variable "private_subnet_ids" {
  description = "Subnets privadas do DB subnet group (mínimo 2 AZs)"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group do RDS (5432 só a partir do SG da EC2)"
  type        = string
}

variable "engine_version" {
  description = "Versão do PostgreSQL (validada com describe-orderable-db-instance-options)"
  type        = string
  default     = "16.13"
}

variable "db_name" {
  type    = string
  default = "reservas"
}

variable "db_username" {
  type    = string
  default = "reservas"
}

variable "db_password" {
  description = "Senha do banco (vem de TF_VAR_db_password; nunca versionada)"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Tags aplicadas a todos os recursos"
  type        = map(string)
  default     = {}
}
