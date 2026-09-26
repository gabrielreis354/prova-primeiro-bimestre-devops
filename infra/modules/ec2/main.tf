# AMI mais recente do Amazon Linux 2023 via parâmetro público do SSM
data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_instance" "this" {
  ami                         = data.aws_ssm_parameter.al2023.value
  instance_type               = "t2.micro"
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.security_group_id]
  associate_public_ip_address = true
  key_name                    = var.key_name
  iam_instance_profile        = var.instance_profile

  metadata_options {
    http_tokens = "required" # IMDSv2
  }

  user_data = templatefile("${path.module}/user_data.sh.tpl", {
    repo_url    = var.repo_url
    repo_ref    = var.repo_ref
    db_host     = var.db_host
    db_name     = var.db_name
    db_user     = var.db_user
    db_password = var.db_password
  })
  user_data_replace_on_change = true

  tags = merge(var.tags, { Name = "${var.name}-api" })
}
