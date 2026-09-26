variable "name" {
  description = "Nome do security group"
  type        = string
}

variable "description" {
  description = "Descrição do security group"
  type        = string
}

variable "vpc_id" {
  description = "VPC onde o security group é criado"
  type        = string
}

variable "ingress_rules" {
  description = <<-EOT
    Regras de entrada TCP, indexadas por um nome estático. Cada regra tem a origem
    em cidr_ipv4 OU em referenced_security_group_id (o outro fica null).
  EOT
  type = map(object({
    description                  = string
    port                         = number
    cidr_ipv4                    = optional(string)
    referenced_security_group_id = optional(string)
  }))

  validation {
    condition = alltrue([
      for r in values(var.ingress_rules) :
      (r.cidr_ipv4 == null) != (r.referenced_security_group_id == null)
    ])
    error_message = "Cada regra deve definir exatamente um entre cidr_ipv4 e referenced_security_group_id."
  }
}

variable "tags" {
  description = "Tags aplicadas a todos os recursos"
  type        = map(string)
  default     = {}
}
