resource "random_string" "linode_password" {
    length  = 32
    special = true
}
resource "linode_instance" "ingress" {
  label             = local.ingress_hostname
  group             = "SaaS"
  tags              = ["Network", "Security", "Shared"]
  region            = local.linode_default_region
  type              = local.linode_default_type
  image             = local.linode_default_image
  authorized_keys   = length(var.public_key) == 0 ? [] : [
    var.public_key
  ]
  authorized_users  = length(var.allowed_linode_username) == 0 ? [] : [
    var.allowed_linode_username
  ]
  root_pass         = random_string.linode_password.result
  stackscript_id    = linode_stackscript.ingress.id
  stackscript_data  = {
    "FQDN"                  = local.ingress_hostname
    "AWS_REGION"            = local.aws_default_region
    "AWS_ACCESS_KEY_ID"     = var.aws_access_key_id
    "AWS_SECRET_ACCESS_KEY" = var.aws_secret_access_key
    "NGINX_VERSION"         = local.nginx_version
    "NJS_VERSION"           = local.njs_version
    "OWASP_BRANCH"          = local.owasp_branch
    "MODSEC_BRANCH"         = local.modsec_branch
    "GEO_DB_RELEASE"        = local.geo_db_release
    "NGINX_SIGNING_CHECKSUM"= local.nginx_signing_checksum
    "SECHTTPBLKEY"          = var.projecthoneypot_key
    "DOMAINS"               = join(" ", local.domains)
  }
  alerts {
      cpu            = 90
      io             = 10000
      network_in     = 10
      network_out    = 10
      transfer_quota = 80
  }
}
output "ingress_id" {
  value = linode_instance.ingress.id
}
output "ingress_ipv4" {
  value = [for ip in linode_instance.ingress.ipv4 : join("/", [ip, "32"])]
}
output "ingress_ipv6" {
  value = linode_instance.ingress.ipv6
}
