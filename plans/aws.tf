resource "aws_ssm_parameter" "ssm_root_password" {
  name        = "/terraform/linode/root_password/${linode_instance.ingress_controller.id}"
  description = join(", ", linode_instance.ingress_controller.ipv4)
  type        = "SecureString"
  value       = random_string.linode_root_password.result
  tags = {
    cost-center = "saas"
  }
}
