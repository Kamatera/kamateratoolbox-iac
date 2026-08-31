variable "admin_kubeconfig_path" {
  type = string
}

variable "controlplane_node_names" {
  type = list(string)
}

variable "letsencrypt_email" {
  type = string
}

variable "nfs_private_ip" {
  type = string
}

variable "nfs_public_ip" {
  type = string
}

variable "server_public_ips" {
  type = any
}

variable "ssh_private_key_file" {
  type = string
}

variable "root_domain" {
  type = string
}

variable "subdomain_prefix" {
  type = string
}

variable "worker_public_ips" {
  type = any
}

variable "initial_admin_user" {
  type = string
}

variable "ssh_pubkey" {
  type = string
}

variable "ssh_additional_authorized_keys" {
  type = any
}

variable "alert_email_addresses" {
  type = string
}