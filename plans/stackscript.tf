data "local_file" "alpine_ingress" {
    filename = "${path.root}/../bin/alpine-ingress"
}
resource "linode_stackscript" "ingress" {
  label = "alpine-waf"
  description = "Installs Nginx with Mod Security"
  script = data.local_file.alpine_ingress.content
  images = [local.linode_default_image]
  rev_note = "v8"
}
output "ingress_stackscript_id" {
  value = linode_stackscript.ingress.id
}
