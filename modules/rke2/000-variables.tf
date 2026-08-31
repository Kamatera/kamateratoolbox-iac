variable "name_prefix" {
  type = string
}

variable "datacenter_id" {
  type = string
}

variable "use_existing_private_network_full_name" {
  type = string
}

variable "servers" {
  type = any
}

variable "ssh_pubkey" {
  type = string
}

variable "ssh_private_key_file" {
  type = string
}

variable "rke2_version" {
  type = string
}

variable "node_token_path" {
  type = string
}

variable "admin_kubeconfig_path" {
  type = string
}
