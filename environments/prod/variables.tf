variable "name_suffix" {description = "global suffix to add to all resource names"}
variable "environment_name" {}
variable "datacenter_id" {description = "Kamatera datacenter id to use for all resources"}
variable "rancher_password" {description = "admin password for Rancher"}
variable "ssh_pubkey_file" {}
variable "ssh_private_key_file" {}
variable "letsencrypt_email" {description = "email address to use for Let's Encrypt account"}
variable "root_domain" {description = "root domain to use for default DNS records"}
variable "subdomain_prefix" {description = "prefix to add to all subdomains under the root_domain"}
variable "initial_admin_user" {description = "personal user name for the first admin user"}
variable "alert_email_addresses" {
  description = "A list of email addresses separated by ;"
}
variable "ssh_additional_authorized_keys_json" {description = "JSON map of additional SSH authorized keys to add to all servers"}
