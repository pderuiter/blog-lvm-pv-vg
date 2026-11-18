# blog-lvm-pv-vg

Companion code for the blog post
[Mastering Physical Volumes and Volume Groups](https://blog.bsdserver.nl/mastering-physical-volumes-and-volume-groups/).

The `lvm_pv_vg` role automates the everyday scenarios from the post:

- **Resizing a disk** (the step-by-step guide and the partition-backed scenario): rescan the grown disk,
  grow the partition with `growpart` when the PV sits on one (the post's tip for automation), then
  `pvresize`.
- **Adding a brand-new disk**: `pvcreate` and `vgextend`.
- **Adding a larger PV and migrating data**: `pvmove` the old PVs onto the new one, then `vgreduce` and
  `pvremove`.
- **Expanding the logical volume** afterwards with its filesystem (`lvresize -r`).

The one-off recovery scenarios (vgcfgrestore, moving disks between machines, vgimportclone,
vgimportdevices, vgsplit, vgck) are deliberately left out: they are steps you take by hand, with care.

Terraform creates an Ubuntu 24.04 VM on Proxmox VE with three data disks. The `lvm_demo` role builds the
starting point of the migration scenario: `my_volume_group` on two small PVs (`/dev/sdb`, `/dev/sdc`) with
a logical volume that spans both. `site.yml` then adds the larger `/dev/sdd`, moves all data onto it and
retires the two small PVs.

## Requirements

- Terraform >= 1.9 and a Proxmox VE API token (the bpg/proxmox provider, pinned in `terraform/versions.tf`).
- Ansible (ansible-core 2.17 or later; tested with 2.22) with the collections in `ansible/requirements.yml`.
- Ubuntu/Debian (tested on Ubuntu 24.04) or RHEL-family hosts (`growpart` comes from `cloud-utils-growpart`
  there).

## Quick start

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars   # endpoint, token, node, IP, SSH key
terraform init
terraform apply
terraform output -raw ansible_inventory > ../ansible/inventory.yml

cd ../ansible
ansible-galaxy collection install -r requirements.yml -p collections
ansible-playbook site.yml      # migrate my_volume_group from sdb+sdc to sdd
ansible-playbook verify.yml    # pvs and vgdisplay from the post, as assertions
```

Then try the resize guide: grow the last disk in `terraform.tfvars` (for example 25 to 35), run
`terraform apply` (Proxmox grows the disk while the VM runs), set `lvm_pv_vg_resize_pvs: [/dev/sdd]` and
run `site.yml` again.

## Variables

| Variable | Default | Meaning |
| --- | --- | --- |
| `lvm_pv_vg_vg` | `my_volume_group` | Volume group to work on |
| `lvm_pv_vg_resize_pvs` | `[]` | PVs on grown disks: a disk (`/dev/sdb`) or a partition (`/dev/sdb1`) |
| `lvm_pv_vg_new_pvs` | `[]` | New disks to add (`pvcreate` + `vgextend`) |
| `lvm_pv_vg_retire_pvs` | `[]` | PVs to empty with `pvmove`, then `vgreduce` and `pvremove` |
| `lvm_pv_vg_migrate_to` | first of `lvm_pv_vg_new_pvs` | Destination PV for `pvmove` |
| `lvm_pv_vg_lv` / `lvm_pv_vg_lv_size` | `""` / `+100%FREE` | LV to grow with its filesystem; empty to skip |
| `lvm_demo_enabled` | `true` in `group_vars` | Build the practice VG first (only when it does not exist yet) |

`pvmove` runs only for PVs that are still in the volume group, so the playbook can be run again after a
migration. Make sure the destination has room for all extents of the PVs you retire.

## Tested

Lab-tested on Ubuntu 24.04 (LVM 2.03.16) with ansible-core 2.22 and community.general 14.0.0:

- migration: an LV spanning two PVs, with a 3 GB file on it, moved onto a third PV; the two old PVs are
  removed, the checksum of the file still matches; the second run reports `changed=0`;
- resize: the disk under the remaining PV grown by 1 GiB at the hypervisor while mounted; the run rescans,
  pvresizes and grows the LV and filesystem; the next run reports `changed=0`;
- a partition-backed PV goes through the `growpart` path (`NOCHANGE` when there is nothing to grow).

Terraform is checked with `fmt -check`, `validate` and `tflint`; `terraform apply` was not run as part of
these tests.

## License

MIT
