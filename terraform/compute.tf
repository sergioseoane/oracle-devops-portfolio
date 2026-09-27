locals {
  cloud_init = <<-EOF2
    #!/bin/bash
    curl -fsSL https://tailscale.com/install.sh | sh
    tailscale up --authkey=${var.tailscale_auth_key} --ssh --hostname=$${HOSTNAME_PLACEHOLDER}
    curl -fsSL https://get.docker.com | sh
    usermod -aG docker ubuntu
  EOF2
}

resource "oci_core_instance" "control_plane" {
  compartment_id      = var.compartment_id
  availability_domain = var.availability_domain
  shape                = "VM.Standard.A1.Flex"
  display_name         = "control-plane"

  shape_config {
    ocpus         = 1
    memory_in_gbs = 6
  }

  source_details {
    source_type = "image"
    source_id   = var.ubuntu_arm_image_id
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.private.id
    assign_public_ip = false
    hostname_label   = "control-plane"
  }

  metadata = {
    ssh_authorized_keys = file(var.ssh_public_key_path)
    user_data            = base64encode(replace(local.cloud_init, "$${HOSTNAME_PLACEHOLDER}", "control-plane"))
  }
}

resource "oci_core_instance" "worker" {
  compartment_id      = var.compartment_id
  availability_domain = var.availability_domain
  shape                = "VM.Standard.A1.Flex"
  display_name         = "worker"

  shape_config {
    ocpus         = 1
    memory_in_gbs = 6
  }

  source_details {
    source_type = "image"
    source_id   = var.ubuntu_arm_image_id
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.private.id
    assign_public_ip = false
    hostname_label   = "worker"
  }

  metadata = {
    ssh_authorized_keys = file(var.ssh_public_key_path)
    user_data            = base64encode(replace(local.cloud_init, "$${HOSTNAME_PLACEHOLDER}", "worker"))
  }
}
