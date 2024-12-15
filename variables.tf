variable "location" {
  type        = string
  description = "Azure region where the resource should be deployed."
  nullable    = false
}

#TODO: verify whether this is required for utility modules
/*
variable "name" {
  type        = string
  description = "The name of the this resource."

  validation {
    condition     = can(regex("TODO", var.name))
    error_message = "The name must be TODO." # TODO remove the example below once complete:
    #condition     = can(regex("^[a-z0-9]{5,50}$", var.name))
    #error_message = "The name must be between 5 and 50 characters long and can only contain lowercase letters and numbers."
  }
}
*/

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
  nullable    = false
}

# tflint-ignore: terraform_unused_declarations
variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) Tags of the resource."
}

variable "location" {
  type        = string
  description = "The selected region for deployment. This is required as the initial query is filtered by location for speed."
}

variable "resource_type" {
  type = string
  description = "The resource type you want a sku for.  Currently only supports VM's, but additional resource types will be added over time."
  default = "vm"
  validation {
    condition     = can(regex("vm", lower(var.resource_type)))
    error_message = "Valid resource types are vm."
  }
}

variable "vm_filters" {
  type = object({
    accelerated_networking_enabled          = optional(bool)
    cpu_architecture_type                   = optional(string, "x64")
    encryption_at_host_supported            = optional(bool)
    ephemeral_os_disk_supported             = optional(bool)
    min_gpus                                = optional(number)
    max_gpus                                = optional(number)
    hibernation_supported                   = optional(bool)
    hyper_v_generations                     = optional(string, "V1,V2")
    low_priority_capable                    = optional(bool)
    memory_preserving_maintenance_supported = optional(bool)
    min_network_interfaces                  = optional(number)
    min_data_disk_count                     = optional(number)
    min_vcpus                               = optional(number)
    max_vcpus                               = optional(number)
    min_memory_gb                           = optional(number)
    max_memory_gb                           = optional(number)
    premium_io_supported                    = optional(bool)
    rdma_enabled                            = optional(bool)
    location_zone                           = optional(number)
    location_ultrassd_support               = optional(bool)
  })


  default = {}
}

variable "cache_results" {
  type = bool
  default = false
  description = "Do you want to write the single random sku output to a cache file? This is to ensure idempotency when re-running the module as sku criteria change over time."
}

variable "cache_storage_details" {
    type = object({
      storage_account_resource_group_name = string
      storage_account_name = string
      storage_account_blob_container_name = string
      storage_account_blob_prefix = string
    })
    description = "If caching to a storage account, these values will be used to write the cache file."
    default = null
}




