output "public_ip" {
  description = "IP público da EC2"
  value       = aws_instance.this.public_ip
}

output "instance_id" {
  value = aws_instance.this.id
}
