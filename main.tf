#### Standalone Instance for Inxpo Environment ####

locals {
  extra_disks = {
    for disk in instance.extra_disks :
    "${var.name}-${disk.disk_name}" => {
      disk_name                 = disk.name
      type                      = disk.type
      size                      = disk.size
      physical_block_size_bytes = disk.physical_block_size_bytes
      zone                      = disk.zone
      key                       = vm_name
    } if vm.extra_disks != null
  }
}

# Create the boot disk for the VMs
resource "google_compute_disk" "boot_disk" {
  name                      = format("%s-boot-disk", var.name)
  type                      = try(var.instance["boot_disk_type"], "pd-standard")
  size                      = var.instance["boot_disk_size"]
  physical_block_size_bytes = 4096
  zone                      = var.instance["zone"]
  image                     = var.instance["image"]

}

# Create the extra disks for the VMs
resource "google_compute_disk" "extra_disks" {

  for_each = extra_disks

  name                      = each.key
  type                      = each.value["type"]
  size                      = each.value["size"]
  physical_block_size_bytes = each.value["physical_block_size_bytes"]
  zone                      = each.value["zone"]
}

# Attach the extra disks to the VMs
resource "google_compute_attached_disk" "attach_disks" {
  for_each = google_compute_disk.extra_disks

  instance = google_compute_instance.default.self_link
  disk     = each.key
}

# Create the VMs
resource "google_compute_instance" "default" {

  name         = var.name
  machine_type = var.instance["machine_type"]
  zone         = var.instance["zone"]
  tags         = var.instance["tags"]
  labels       = var.instance["labels"]

  enable_display            = var.instance["enable_display"]
  allow_stopping_for_update = var.instance["allow_stopping_for_update"]

  boot_disk {
    source = google_compute_disk.boot_disk.self_link
  }
  network_interface {
    network    = var.vpc_name
    subnetwork = var.subnetwork
    nic_type   = var.instance["nic_type"]
  }
  service_account {
    email  = var.instance["service_account"]["email"]
    scopes = var.instance["service_account"]["scopes"]
  }

  #metadata = try(var.instance.win_domain_join_metadata[0], null) # set metadata if it exists, always going to be a list of one object
  metadata = (merge(try(var.instance.vm_startup_metadata[0], null), { "windows-startup-script-ps1" = try(file(var.instance.vm_startup_script), null) }))


  lifecycle {
    ignore_changes = [
      allow_stopping_for_update,
      enable_display,
      attached_disk
    ]
  }
}

data "route53_zone" "default" {
  name = var.domain_name
}

resource "route53_record" "instance" {

  zone_id = data.route53_zone.default.zone_id
  name    = var.name
  type    = "A"
  ttl     = "300"
  records = [google_compute_instance.default.network_interface.0.network_ip]
}