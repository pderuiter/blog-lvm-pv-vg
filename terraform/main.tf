resource "proxmox_download_file" "ubuntu_noble" {
  content_type = "import"
  datastore_id = var.image_datastore_id
  node_name    = var.node_name
  url          = var.image_url
  file_name    = "noble-server-cloudimg-amd64.qcow2"
}

resource "proxmox_virtual_environment_vm" "this" {
  for_each = var.vms

  name          = each.key
  node_name     = var.node_name
  vm_id         = each.value.vm_id
  scsi_hardware = "virtio-scsi-single"
  tags          = ["blog"]

  agent {
    enabled = false
  }

  cpu {
    cores = each.value.cores
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = each.value.memory
  }

  operating_system {
    type = "l26"
  }

  disk {
    datastore_id = var.datastore_id
    import_from  = proxmox_download_file.ubuntu_noble.id
    interface    = "scsi0"
    size         = var.os_disk_size
    iothread     = true
    discard      = "on"
  }

  dynamic "disk" {
    for_each = each.value.data_disks
    content {
      datastore_id = var.datastore_id
      interface    = "scsi${disk.key + 1}"
      size         = disk.value
      file_format  = "raw"
      iothread     = true
      discard      = "on"
    }
  }

  dynamic "network_device" {
    for_each = var.bridges
    content {
      bridge = network_device.value
    }
  }

  initialization {
    datastore_id = var.datastore_id

    dns {
      servers = var.dns_servers
    }

    dynamic "ip_config" {
      for_each = each.value.addresses
      content {
        ipv4 {
          address = ip_config.value
          gateway = ip_config.key == 0 ? var.gateway : null
        }
      }
    }

    user_account {
      username = var.ssh_username
      keys     = [var.ssh_public_key]
    }
  }
}
