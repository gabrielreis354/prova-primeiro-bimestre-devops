variable "aws_region" {
  description = "Região do Learner Lab"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefixo dos nomes dos recursos"
  type        = string
  default     = "technova-reservas"
}

variable "azs" {
  description = "AZs com suporte a t2.micro e db.t3.micro (validado com a AWS CLI)"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "ssh_cidr" {
  description = "CIDR autorizado no SSH (22): o IP do aluno em /32. Sem default de propósito."
  type        = string

  validation {
    condition     = can(cidrhost(var.ssh_cidr, 0)) && var.ssh_cidr != "0.0.0.0/0"
    error_message = "ssh_cidr deve ser um CIDR válido e diferente de 0.0.0.0/0 (use seu IP/32)."
  }
}

variable "db_password" {
  description = "Senha do RDS. Defina via TF_VAR_db_password; nunca em arquivo versionado."
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^[A-Za-z0-9_.-]{8,}$", var.db_password))
    error_message = "Use 8+ caracteres entre letras, números, _ . - (o valor vai entre aspas simples no user_data)."
  }
}

variable "repo_url" {
  description = "Repositório público da prova, clonado pela EC2"
  type        = string
  default     = "https://github.com/gabrielreis354/prova-primeiro-bimestre-devops.git"
}

variable "repo_ref" {
  description = "Tag ou commit do repositório que a EC2 executa"
  type        = string
  default     = "v0.9-apply"
}
