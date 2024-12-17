variable "location" {
  type        = string
  description = "Azure region where the target skus will be deployed. This is required as the initial api query is filtered by location for speed."
  nullable    = false
}

variable "cache_results" {
  type        = bool
  default     = false
  description = "Do you want to write the single random sku output to a cache file? This is to ensure idempotency when re-running the module as sku criteria change over time."
}

#TODO: create a full description of the cache_storage_details object
variable "cache_storage_details" {
  type = object({
    storage_account_resource_group_name = string
    storage_account_name                = string
    storage_account_blob_container_name = string
    storage_account_blob_prefix         = string
  })
  default     = null
  description = <<DESCRIPTION
This object is used to define the storage account and container where the cache file will be stored.

- `storage_account_resource_group_name` - The name of the resource group where the storage account is located.
- `storage_account_name` - The name of the storage account where the cache file will be stored.
- `storage_account_blob_container_name` - The name of the container where the cache file will be stored.
- `storage_account_blob_prefix` - The prefix to be used for the cache file blob.

DESCRIPTION
}

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

variable "local_cache_prefix" {
  type        = string
  default     = "local"
  description = "If caching locally, this prefix will be used to help identify the cache file in the event that the module is called multiple times."
}

variable "resource_type" {
  type        = string
  default     = "vm"
  description = "The resource type you want a sku for.  Currently only supports VM's, but additional resource types will be added over time."

  validation {
    condition     = can(regex("vm", lower(var.resource_type)))
    error_message = "Valid resource types are vm."
  }
}

#TODO: create a full description of the vm_filters object
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
  default     = {}
  description = <<DESCRIPTION
This object is used to filter the available skus based on the criteria you provide.

- `accelerated_networking_enabled` - If true, only skus that support accelerated networking will be returned.
- `cpu_architecture_type` - The cpu architecture type.  Valid values are `x64` and `Arm64`.
- `encryption_at_host_supported` - If true, only skus that support encryption at host will be returned.
- `ephemeral_os_disk_supported` - If true, only skus that support ephemeral os disks will be returned.
- `min_gpus` - The minimum number of gpus the sku must support.
- `max_gpus` - The maximum number of gpus the sku must support. 
- `hibernation_supported` - If true, only skus that support hibernation will be returned.
- `hyper_v_generations` - The hyper-v generations the sku must support.  Valid values are `V1`, `V2`, and `V1,V2`.
- `low_priority_capable` - If true, only skus that support low priority will be returned.
- `memory_preserving_maintenance_supported` - If true, only skus that support memory preserving maintenance will be returned.
- `min_network_interfaces` - The minimum number of network interfaces the sku must support.
- `min_data_disk_count` - The minimum number of data disks the sku must support.
- `min_vcpus` - The minimum number of vcpus the sku must support.
- `max_vcpus` - The maximum number of vcpus the sku must support.
- `min_memory_gb` - The minimum amount of memory in GB the sku must support.
- `max_memory_gb` - The maximum amount of memory in GB the sku must support.
- `premium_io_supported` - If true, only skus that support premium io will be returned.
- `rdma_enabled` - If true, only skus that support rdma will be returned.
- `location_zone` - Will return skus that are supported in the specified zone in your subscription.
- `location_ultrassd_support` - If true, only skus that support ultra ssd will be returned.

DESCRIPTION
}
