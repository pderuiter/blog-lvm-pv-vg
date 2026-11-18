locals {
  inventory_groups = distinct(flatten([for vm in values(var.vms) : vm.groups]))
}

output "ansible_inventory" {
  description = "Ansible inventory in YAML; save it with: terraform output -raw ansible_inventory > ../ansible/inventory.yml"
  value = yamlencode({
    all = {
      vars = {
        ansible_user = var.ssh_username
      }
      children = {
        for group in local.inventory_groups : group => {
          hosts = {
            for name, vm in var.vms : name => {
              ansible_host = split("/", vm.addresses[0])[0]
            } if contains(vm.groups, group)
          }
        }
      }
    }
  })
}

output "vm_ids" {
  description = "Proxmox VM IDs per VM name"
  value       = { for name, vm in proxmox_virtual_environment_vm.this : name => vm.vm_id }
}
