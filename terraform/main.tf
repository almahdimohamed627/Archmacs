terraform {
  required_version = ">= 1.0"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.7"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

# Variables
variable "iso_path" {
  description = "Path to the built ISO file"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
  default     = ""
}

variable "test_vm_memory" {
  description = "Memory in MB for test VM"
  type        = number
  default     = 4096
}

variable "test_vm_vcpu" {
  description = "Number of vCPUs for test VM"
  type        = number
  default     = 2
}

variable "test_vm_disk_size" {
  description = "Disk size in GB for test VM"
  type        = number
  default     = 20
}

# Local values
locals {
  timestamp = formatdate("YYYY-MM-DD", timestamp())
  ssh_key   = var.ssh_public_key != "" ? var.ssh_public_key : file("~/.ssh/id_rsa.pub")
}

# Create network for testing
resource "libvirt_network" "test_network" {
  name      = "archmacs-test"
  mode      = "nat"
  domain    = "archmacs.test"
  addresses = ["192.168.100.0/24"]

  dns {
    enabled = true
  }
}

# Create storage pool for ISOs
resource "libvirt_pool" "iso_pool" {
  name = "archmacs-iso"
  type = "dir"
  path = "/var/lib/libvirt/archmacs-iso"
}

# Create storage pool for VM disks
resource "libvirt_pool" "vm_pool" {
  name = "archmacs-vm"
  type = "dir"
  path = "/var/lib/libvirt/archmacs-vm"
}

# Upload the built ISO to the pool
resource "libvirt_volume" "archmacs_iso" {
  name   = "archmacs.iso"
  pool   = libvirt_pool.iso_pool.name
  source = var.iso_path
  format = "raw"
}

# Create base volume for test VM (using cloud image)
resource "libvirt_volume" "test_vm_base" {
  name   = "test_vm_base.qcow2"
  pool   = libvirt_pool.vm_pool.name
  size   = var.test_vm_disk_size * 1024 * 1024 * 1024
  base_volume_id = libvirt_volume.archmacs_iso.id
  format = "qcow2"
}

# Create cloud-init disk for SSH access
resource "libvirt_cloudinit_disk" "test_vm_cloudinit" {
  name      = "test_vm_cloudinit.iso"
  pool      = libvirt_pool.iso_pool.name
  user_data = templatefile("${path.module}/cloud-init/meta-data", {
    hostname    = "archmacs-test"
    ssh_public_key = local.ssh_key
  })
  network_config = templatefile("${path.module}/cloud-init/network-config", {})
}

# Test VM
module "test_vm" {
  source = "./modules/test-vm"

  vm_name       = "archmacs-test-vm"
  vcpu          = var.test_vm_vcpu
  memory        = var.test_vm_memory
  disk_size     = var.test_vm_disk_size
  iso_volume_id = libvirt_volume.archmacs_iso.id
  cloudinit_id  = libvirt_cloudinit_disk.test_vm_cloudinit.id
  network_id    = libvirt_network.test_network.id
}

# Wait for VM to boot and SSH to be ready
resource "null_resource" "wait_for_ssh" {
  depends_on = [module.test_vm]

  connection {
    type        = "ssh"
    user        = "archuser"
    host        = module.test_vm.vm_ip
    port        = 22
    private_key = file("~/.ssh/id_rsa")
    timeout     = "10m"
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'SSH connection established successfully'",
      "uptime",
      "whoami"
    ]
  }
}

# Copy test scripts to VM
resource "null_resource" "copy_tests" {
  depends_on = [null_resource.wait_for_ssh]

  connection {
    type        = "ssh"
    user        = "archuser"
    host        = module.test_vm.vm_ip
    private_key = file("~/.ssh/id_rsa")
  }

  provisioner "file" {
    source      = "../tests/"
    destination = "/tmp/tests/"
  }
}

# Run automated tests
resource "null_resource" "run_tests" {
  depends_on = [null_resource.copy_tests]

  connection {
    type        = "ssh"
    user        = "archuser"
    host        = module.test_vm.vm_ip
    private_key = file("~/.ssh/id_rsa")
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /tmp/tests/run-tests.sh",
      "sudo /tmp/tests/run-tests.sh"
    ]
  }
}

# Outputs
output "test_vm_ip" {
  description = "IP address of the test VM"
  value       = module.test_vm.vm_ip
}

output "test_vm_name" {
  description = "Name of the test VM"
  value       = module.test_vm.vm_name
}

output "network_name" {
  description = "Name of the test network"
  value       = libvirt_network.test_network.name
}

output "iso_path" {
  description = "Path to the ISO used"
  value       = libvirt_volume.archmacs_iso.source
}
