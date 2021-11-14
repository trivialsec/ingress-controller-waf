resource "aws_ssm_parameter" "ssm_linode_password" {
  name        = "/linode/${linode_instance.ingress.id}/linode_elasticsearch_password"
  description = join(", ", linode_instance.ingress.ipv4)
  type        = "SecureString"
  value       = random_string.linode_password.result
  tags = {
    cost-center = "saas"
  }
}
