variable "project" {
  description = "project name"
  type        = string
}

variable "region" {
  description = "region"
  type        = string
}

variable "vpc_name" {
  description = "VPC Network name"
  type        = string
}

variable "subnetwork" {
  description = "Subnetwork name"
  type        = string

}

variable "name" {
  description = "Name of the instance"
  type        = string
}

variable "create_dns_record" {
  description = "Create external DNS record for the instance"
  type        = bool
  default     = false
}

variable "domain" {
  description = "Domain name used to create DNS records"
  type        = string
}

variable "instance" {
  description = "The configurations for the VMs to be created."
  type = object({
    name                      = string
    machine_type              = string
    image                     = string
    boot_disk_size            = number
    zone                      = string
    disk_type                 = optional(string)
    tags                      = optional(list(string))
    delete_protection         = optional(bool)
    enable_display            = optional(bool) # Enable display for Windows VMs to capture screenshots
    allow_stopping_for_update = optional(bool) # Allow the instance to be stopped for update
    labels                    = optional(map(string))

    extra_disks = optional(list(object({ # The extra disks to be attached to the VM
      name                      = string
      type                      = string
      size                      = string
      physical_block_size_bytes = number
      zone                      = string

    })))

    # Network interface configuration
    nic_type   = optional(string)
    stack_type = optional(string)
    access_config = optional(list(object({
      nat_ip       = string
      network_tier = string
    })))

    service_account = object({
      email  = string
      scopes = set(string)
    })

    vm_startup_script = optional(string)         # The path to the startup script for the VM
    vm_startup_metadata = optional(list(object({ # The metadata for domain join
      windows-startup-script-url          = string
      managed-ad-domain                   = string
      managed-ad-domain-join-failure-stop = string
      enable-guest-attributes             = string
      #managed-ad-ou-name                  = string
    })))

  })

  default = {}
}

