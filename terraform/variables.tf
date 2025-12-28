variable "iso_path" {
  description = "Path to the built ISO file"
  type        = string
  default     = "../out/archmacs.iso"
}

variable "ssh_public_key" {
  description = "SSH public key for VM access (optional, defaults to ~/.ssh/id_rsa.pub)"
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

variable "test_vm_count" {
  description = "Number of test VMs to create"
  type        = number
  default     = 1
}

variable "destroy_after_test" {
  description = "Destroy VMs after running tests"
  type        = bool
  default     = false
}
