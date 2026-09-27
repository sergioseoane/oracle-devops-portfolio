variable "tenancy_ocid" {
  description = "OCID de Oracle Cloud (formato: ocid1.tipo.oc1..xxxx)"
  type        = string
}

variable "compartment_id" {
  description = "OCID de Oracle Cloud (formato: ocid1.tipo.oc1..xxxx)"
  type        = string
  default     = null
}

variable "region" {
  description = "Región de Oracle Cloud"
  type        = string
  default     = "eu-madrid-1"
}


variable "tailscale_auth_key" {
  type      = string
  sensitive = true
}

variable "availability_domain" {
  description = "Availability domain de Oracle Cloud"
  type        = string
}

variable "ubuntu_arm_image_id" {
  description = "OCID de la imagen Ubuntu 22.04 ARM"
  type        = string
}

variable "ssh_public_key_path" {
  description = "Ruta a la clave pública SSH"
  type        = string
  default     = "~/.ssh/oracle_devops.pub"
}
