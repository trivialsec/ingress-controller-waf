locals {
    aws_default_region      = "ap-southeast-2"
    aws_master_account_id   = 984310022655
    linode_default_region   = "ap-southeast"
    linode_default_image    = "linode/alpine3.14"
    linode_default_type     = "g6-nanode-1"
    route53_hosted_zone     = "Z04169281YCJD2GS4F5ER"
    ingress_hostname        = "prd-ingress.trivialsec.com"
    nginx_version           = "1.20.1"
    njs_version             = "0.7.0"
    owasp_branch            = "v3.3/master"
    modsec_branch           = "v3.0.4"
    geo_db_release          = "2021-11"
    nginx_signing_checksum  = "e7fa8303923d9b95db37a77ad46c68fd4755ff935d0a534d26eba83de193c76166c68bfe7f65471bf8881004ef4aa6df3e34689c305662750c0172fca5d8552a"
    domains                 = [
        "es.trivialsec.com",
        "push.trivialsec.com",
        "app.trivialsec.com",
        "api.trivialsec.com",
        "batch.trivialsec.com",
    ]
}
