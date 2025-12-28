variable "vm_name" {}
variable "vcpu" {}
variable "memory" {}
variable "disk_size" {}
variable "iso_volume_id" {}
variable "cloudinit_id" {}
variable "network_id" {}

# Create disk volume for VM
resource "libvirt_volume" "vm_disk" {
  name   = "${var.vm_name}-disk.qcow2"
  pool   = "/var/lib/libvirt/archmacs-vm"
  size   = var.disk_size * 1024 * 1024 * 1024
  format = "qcow2"
}

# VM domain
resource "libvirt_domain" "vm" {
  name   = var.vm_name
  memory = var.memory
  vcpu   = var.vcpu

  network_interface {
    network_id     = var.network_id
    wait_for_lease = true
  }

  disk {
    volume_id = var.iso_volume_id
  }

  disk {
    volume_id = var.cloudinit_id
  }

  disk {
    volume_id = libvirt_volume.vm_disk.id
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }

  features {
    acpi = "on"
    apic = "on"
  }

  cpu {
    mode = "host-passthrough"
  }

  xml {
    xslt = <<-EOT
      <xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
        <xsl:output method="xml" indent="yes"/>
        <xsl:template match="@*|node()">
          <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
          </xsl:copy>
        </xsl:template>
        <xsl:template match="/domain/devices/disk[@device='disk'][1]">
          <xsl:copy>
            <xsl:attribute name="boot">1</xsl:attribute>
            <xsl:apply-templates select="@*|node()"/>
          </xsl:copy>
        </xsl:template>
      </xsl:stylesheet>
    EOT
  }
}

# Get VM IP address
data "libvirt_network_dns_host" "vm_dns" {
  count      = 30
  depends_on = [libvirt_domain.vm]
  name       = var.vm_name
  ip         = null
  network_id = var.network_id
}

output "vm_name" {
  value = var.vm_name
}

output "vm_ip" {
  value = data.libvirt_network_dns_host.vm_dns[count.index].ip
}
