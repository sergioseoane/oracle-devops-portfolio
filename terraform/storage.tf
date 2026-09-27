resource "oci_core_volume" "riddim_music" {
  compartment_id      = var.compartment_id
  availability_domain = var.availability_domain
  display_name         = "riddim-music-storage"
  size_in_gbs           = 50
}

resource "oci_core_volume_attachment" "riddim_music_attach" {
  attachment_type = "paravirtualized"
  instance_id      = oci_core_instance.worker.id
  volume_id        = oci_core_volume.riddim_music.id
  display_name      = "riddim-music-attachment"
}
