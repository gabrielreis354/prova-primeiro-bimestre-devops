locals {
  tags = {
    Project   = "prova-primeiro-bimestre"
    Owner     = "Gabriel-Reis-Cunha"
    RA        = "6325149"
    ManagedBy = "terraform"
  }
}

module "vpc" {
  source = "./modules/vpc"

  name = var.project_name
  azs  = var.azs
  tags = local.tags
}

module "sg_ec2" {
  source = "./modules/security-group"

  name        = "${var.project_name}-ec2-sg"
  description = "EC2 da API: SSH restrito ao IP do aluno e porta 3000"
  vpc_id      = module.vpc.vpc_id
  tags        = local.tags

  ingress_rules = {
    ssh = { description = "SSH do IP do aluno", port = 22, cidr_ipv4 = var.ssh_cidr }
    api = { description = "API de Reservas", port = 3000, cidr_ipv4 = "0.0.0.0/0" }
  }
}

module "sg_rds" {
  source = "./modules/security-group"

  name        = "${var.project_name}-rds-sg"
  description = "RDS PostgreSQL: 5432 apenas a partir do SG da EC2"
  vpc_id      = module.vpc.vpc_id
  tags        = local.tags

  ingress_rules = {
    postgres = {
      description                  = "PostgreSQL somente do SG da EC2"
      port                         = 5432
      referenced_security_group_id = module.sg_ec2.sg_id
    }
  }
}

module "rds" {
  source = "./modules/rds"

  name               = var.project_name
  private_subnet_ids = module.vpc.private_subnet_ids
  security_group_id  = module.sg_rds.sg_id
  db_password        = var.db_password
  tags               = local.tags
}

module "ec2" {
  source = "./modules/ec2"

  name              = var.project_name
  subnet_id         = module.vpc.public_subnet_ids[0]
  security_group_id = module.sg_ec2.sg_id
  repo_url          = var.repo_url
  repo_ref          = var.repo_ref
  db_host           = module.rds.address
  db_name           = module.rds.db_name
  db_user           = module.rds.db_username
  db_password       = var.db_password
  tags              = local.tags
}
