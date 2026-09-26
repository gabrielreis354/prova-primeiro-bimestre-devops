variable "name" {
  description = "Prefixo dos nomes dos recursos"
  type        = string
}

variable "subnet_id" {
  description = "Subnet pública onde a instância sobe"
  type        = string
}

variable "security_group_id" {
  description = "Security group da EC2 (22 e 3000)"
  type        = string
}

variable "key_name" {
  description = "Key pair já existente no Lab (nenhum .pem no repositório)"
  type        = string
  default     = "vockey"
}

variable "instance_profile" {
  description = "Instance profile pré-existente do Learner Lab (sem criar IAM)"
  type        = string
  default     = "LabInstanceProfile"
}

variable "repo_url" {
  description = "Repositório público com o código da API"
  type        = string
}

variable "repo_ref" {
  description = "Tag ou commit clonado pelo user_data"
  type        = string
}

variable "db_host" {
  type = string
}

variable "db_name" {
  type = string
}

variable "db_user" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "tags" {
  description = "Tags aplicadas a todos os recursos"
  type        = map(string)
  default     = {}
}
