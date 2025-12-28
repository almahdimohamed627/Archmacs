output "test_vm_ips" {
  description = "IP addresses of the test VMs"
  value       = module.test_vm.vm_ip
}

output "test_vm_names" {
  description = "Names of the test VMs"
  value       = module.test_vm.vm_name
}

output "network_name" {
  description = "Name of the test network"
  value       = libvirt_network.test_network.name
}

output "network_subnet" {
  description = "Subnet of the test network"
  value       = libvirt_network.test_network.addresses[0]
}

output "iso_path" {
  description = "Path to the ISO used"
  value       = libvirt_volume.archmacs_iso.source
}

output "ssh_command" {
  description = "SSH command to connect to the test VM"
  value       = "ssh -o StrictHostKeyChecking=no archuser@${module.test_vm.vm_ip}"
}
