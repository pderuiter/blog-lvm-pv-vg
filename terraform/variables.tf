variable "proxmox_endpoint" {
  description = "Proxmox VE API endpoint, for example https://pve.example.com:8006/"
  type        = string
}

variable "proxmox_api_token" {
  description = "Proxmox VE API token in the form user@realm!tokenid=secret"
  type        = string
  sensitive   = true
}

variable "proxmox_insecure" {
  description = "Skip TLS verification of the Proxmox VE API (self-signed certificates)"
  type        = bool
  default     = false
}

variable "node_name" {
  description = "Proxmox VE node that hosts the VMs"
  type        = string
}

variable "datastore_id" {
  description = "Datastore for the VM disks and the cloud-init drive"
  type        = string
  default     = "local-lvm"
}

variable "image_datastore_id" {
  description = "Datastore with the 'import' content type that stores the Ubuntu cloud image"
  type        = string
  default     = "local"
}

variable "image_url" {
  description = "Ubuntu 24.04 (Noble) cloud image"
  type        = string
  default     = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
}

variable "bridges" {
  description = "Network bridges; one NIC per bridge is added to every VM, in this order"
  type        = list(string)
  default     = ["vmbr0"]
}

variable "gateway" {
  description = "IPv4 default gateway, configured on the first NIC"
  type        = string
}

variable "dns_servers" {
  description = "DNS servers for the VMs"
  type        = list(string)
  default     = ["10.0.10.1"]
}

variable "ssh_username" {
  description = "User created by cloud-init; Ansible connects as this user"
  type        = string
  default     = "ansible"
}

variable "ssh_public_key" {
  description = "SSH public key for ssh_username"
  type        = string
}

variable "os_disk_size" {
  description = "Size of the OS disk (scsi0) in GiB"
  type        = number
  default     = 20
}

variable "vms" {
  description = <<-EOT
    VMs to create. addresses: one IPv4 address in CIDR notation per bridge.
    data_disks: sizes in GiB of extra disks; they become scsi1, scsi2, ... (/dev/sdb, /dev/sdc, ... in the guest).
    Increase a size and apply again to grow that disk while the VM keeps running.
    groups: Ansible inventory groups for this VM.
  EOT
  type = map(object({
    vm_id      = optional(number)
    cores      = optional(number, 2)
    memory     = optional(number, 2048)
    addresses  = list(string)
    data_disks = optional(list(number), [])
    groups     = list(string)
  }))
}
