output "dns" {
  value = {
    "ingress_hostname" = values(cloudflare_record.default_ingress)[0].hostname
    "hostnames" = concat(
      [
        cloudflare_record.cloudcli.hostname
      ],
      [
        for each in cloudflare_record.default_sub_domains : each.hostname
      ]
    )
  }
}
