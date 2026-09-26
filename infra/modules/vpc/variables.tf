variable "name" {
  description = "Prefixo dos nomes dos recursos"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR da VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Zonas de disponibilidade (uma subnet pública e uma privada por AZ)"
  type        = list(string)
}

variable "tags" {
  description = "Tags aplicadas a todos os recursos"
  type        = map(string)
  default     = {}
}
