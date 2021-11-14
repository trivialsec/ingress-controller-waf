resource "aws_route53_record" "a" {
    zone_id = local.route53_hosted_zone
    name    = local.ingress_hostname
    type    = "A"
    ttl     = 300
    records = linode_instance.ingress.ipv4
}
resource "aws_route53_record" "aaaa" {
    zone_id = local.route53_hosted_zone
    name    = local.ingress_hostname
    type    = "AAAA"
    ttl     = 300
    records = [
        element(split("/", linode_instance.ingress.ipv6), 0)
    ]
}
resource "aws_route53_record" "sites_a" {
    count   = length(local.domains)
    zone_id = local.route53_hosted_zone
    name    = local.domains[count.index]
    type    = "A"
    ttl     = 300
    records = linode_instance.ingress.ipv4
}
resource "aws_route53_record" "sites_aaaa" {
    count   = length(local.domains)
    zone_id = local.route53_hosted_zone
    name    = local.domains[count.index]
    type    = "AAAA"
    ttl     = 300
    records = [
        element(split("/", linode_instance.ingress.ipv6), 0)
    ]
}
