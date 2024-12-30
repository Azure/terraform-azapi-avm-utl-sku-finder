#get the full sku list (azapi doesn't currently have a good way to filter the api call)
data "azapi_resource_list" "vm" {
  count = lower(var.resource_type) == "vm" ? 1 : 0

  parent_id              = data.azurerm_subscription.current.id
  type                   = "Microsoft.Compute/skus?$filter=location%20eq%20%27${lower(var.location)}%27@2024-07-01"
  response_export_values = ["*"]
}

locals {
  #narrow the sku list 
  no_restriction = lower(var.resource_type) == "vm" ? [for sku in data.azapi_resource_list.vm[0].output.value : sku.name
    if
    length(sku.restrictions) < 1 &&                 #there are no region restrictions
    lower(sku.resourceType) == "virtualmachines" && #sku is a virtual machine type
    length(try(sku.capabilities, [])) > 1           #avoid skus without a defined capabilities list
  ] : []
  vm_cache_map = {
    sku      = tolist(local.vm_skus)[random_integer.vm_deploy_sku.result]
    sku_list = tolist(local.vm_skus)
  }
  vm_duplicates                  = ((lower(var.resource_type) == "vm") ? [for key, value in local.vm_find_duplicates : key if length(value) > 1] : []) #any group with more than 1 value is a duplicate)
  vm_find_duplicates             = try({ for sku in data.azapi_resource_list.vm[0].output.value : sku.name => sku... }, {})                            #group the output to ensure duplicates can be identified
  vm_location_capabilities       = lower(var.resource_type) == "vm" ? { for key, value in local.vm_map_location_conversion : key => try({ for capability in value[lower(var.location)].zoneDetails[0].capabilities : capability.name => capability }, {}) } : {}
  vm_map_capabilities_conversion = lower(var.resource_type) == "vm" ? { for sku in local.vm_map_conversion : sku.name => { for capability in sku.capabilities : capability.name => capability } } : {}                                           #convert the capabilities a map so we can work with the keys
  vm_map_conversion              = lower(var.resource_type) == "vm" ? { for sku in data.azapi_resource_list.vm[0].output.value : sku.name => sku if(!contains(local.vm_duplicates, sku.name) && contains(local.no_restriction, sku.name)) } : {} #convert the output to a map so we can work with the keys
  vm_map_location_conversion     = lower(var.resource_type) == "vm" ? { for sku in local.vm_map_conversion : sku.name => { for location in sku.locationInfo : lower(location.location) => location } } : {}                                      #convert the locationInfo to a map so we can work with the keys 
  vm_output_map = {
    "vm" = {
      sku      = ((lower(var.resource_type) == "vm" && var.cache_results) ? (var.cache_storage_details == null ? jsondecode(local_file.local_sku_cache[0].content).sku : jsondecode(azurerm_storage_blob.cache[0].source_content).sku) : (lower(var.resource_type == "vm") ? local.cache_map[lower(var.resource_type)].sku : "no_valid_skus_found"))
      sku_list = (lower(var.resource_type) == "vm" && var.cache_results) ? (var.cache_storage_details == null ? jsondecode(local_file.local_sku_cache[0].content).sku_list : jsondecode(azurerm_storage_blob.cache[0].source_content).sku_list) : (lower(var.resource_type == "vm") ? local.vm_skus : toset([]))
    }
  }
  #Create separate lists of skus based on the conditions input for each capability 
  vm_per_element_valid_skus = lower(var.resource_type) == "vm" ? {

    #required selection (defaults to x64).  Matching only, no null comparisons.
    CpuArchitectureType = [for sku, value in local.vm_map_capabilities_conversion : sku if
      (
        (try(lower(value["CpuArchitectureType"].value) == lower(tostring(var.vm_filters.cpu_architecture_type)), false))
      )
    ]

    #null = all skus 
    #value = matching skus only
    AcceleratedNetworkingEnabled = [for sku, value in local.vm_map_capabilities_conversion : sku if
      (
        (try(lower(value["AcceleratedNetworkingEnabled"].value) == lower(tostring(var.vm_filters.accelerated_networking_enabled)), false)) ||
        var.vm_filters.accelerated_networking_enabled == null
      )
    ],
    EncryptionAtHostSupported = [for sku, value in local.vm_map_capabilities_conversion : sku if
      (
        (try(lower(value["EncryptionAtHostSupported"].value) == lower(tostring(var.vm_filters.encryption_at_host_supported)), false)) ||
        var.vm_filters.encryption_at_host_supported == null
      )
    ],
    EphemeralOSDiskSupported = [for sku, value in local.vm_map_capabilities_conversion : sku if
      (
        (try(lower(value["EphemeralOSDiskSupported"].value) == lower(tostring(var.vm_filters.ephemeral_os_disk_supported)), false)) ||
        var.vm_filters.ephemeral_os_disk_supported == null
      )
    ],
    HibernationSupported = [for sku, value in local.vm_map_capabilities_conversion : sku if
      (
        (try(lower(value["HibernationSupported"].value) == lower(tostring(var.vm_filters.hibernation_supported)), false)) ||
        var.vm_filters.hibernation_supported == null
      )
    ],
    LowPriorityCapable = [for sku, value in local.vm_map_capabilities_conversion : sku if
      (
        (try(lower(value["LowPriorityCapable"].value) == lower(tostring(var.vm_filters.low_priority_capable)), false)) ||
        var.vm_filters.low_priority_capable == null
      )
    ],
    MemoryPreservingMaintenanceSupported = [for sku, value in local.vm_map_capabilities_conversion : sku if
      (
        (try(lower(value["MemoryPreservingMaintenanceSupported"].value) == lower(tostring(var.vm_filters.memory_preserving_maintenance_supported)), false)) ||
        var.vm_filters.memory_preserving_maintenance_supported == null
      )
    ],
    PremiumIO = [for sku, value in local.vm_map_capabilities_conversion : sku if
      (
        (try(lower(value["PremiumIO"].value) == lower(tostring(var.vm_filters.premium_io_supported)), false)) ||
        var.vm_filters.premium_io_supported == null
      )
    ],
    RdmaEnabled = [for sku, value in local.vm_map_capabilities_conversion : sku if
      (
        (try(lower(value["RdmaEnabled"].value) == lower(tostring(var.vm_filters.rdma_enabled)), false)) ||
        var.vm_filters.rdma_enabled == null
      )
    ],

    #null for min and max include everything
    #min defined and capabilities value defined for sku, null max include skus with greater than min
    #max defined,and capabilities valued defined for sku, null min = include skus with less than max
    #min and max defined = include sku's equal to or between the min and max
    vCPUs_min = [for sku, value in local.vm_map_capabilities_conversion : sku if
      (
        (try(tonumber(value["vCPUs"].value) >= var.vm_filters.min_vcpus, false)) ||
        var.vm_filters.min_vcpus == null
      )
    ],
    vCPUs_max = [for sku, value in local.vm_map_capabilities_conversion : sku if
      (
        (try(tonumber(value["vCPUs"].value) <= var.vm_filters.max_vcpus, false)) ||
        var.vm_filters.max_vcpus == null
      )
    ],

    MemoryGB_min = [for sku, value in local.vm_map_capabilities_conversion : sku if
      (
        (try(tonumber(value["MemoryGB"].value) >= var.vm_filters.min_memory_gb, false)) ||
        var.vm_filters.min_memory_gb == null
      )
    ],
    MemoryGB_max = [for sku, value in local.vm_map_capabilities_conversion : sku if
      (
        (try(tonumber(value["MemoryGB"].value) <= var.vm_filters.max_memory_gb, false)) ||
        var.vm_filters.max_memory_gb == null
      )
    ],

    GPUs_min = [for sku, value in local.vm_map_capabilities_conversion : sku if
      (
        (try(tonumber(value["GPUs"].value) >= var.vm_filters.min_gpus, false)) ||
        var.vm_filters.min_gpus == null
      )
    ],
    GPUs_max = [for sku, value in local.vm_map_capabilities_conversion : sku if
      (
        (try(tonumber(value["GPUs"].value) <= var.vm_filters.max_gpus, false)) ||
        var.vm_filters.max_gpus == null
      )
    ],

    #minimum value supplied.  Outcome is sku's supporting at least that many NICs.  Unlikely that someone would want sku's supporting less than some maximum nic count.  Leaving that condition unset for now.
    MaxNetworkInterfaces_min = [for sku, value in local.vm_map_capabilities_conversion : sku if
      (
        (try(tonumber(value["MaxNetworkInterfaces"].value) >= var.vm_filters.min_network_interfaces, false)) ||
        var.vm_filters.min_network_interfaces == null
      )
    ],

    #minimum value supplied.  Outcome is sku's supporting at least that many Data disks.  Unlikely that someone would want sku's supporting less than some maximum data disk count.  Leaving that condition unset for now.
    MaxDataDiskCount_min = [for sku, value in local.vm_map_capabilities_conversion : sku if
      (
        (try(tonumber(value["MaxDataDiskCount"].value) >= var.vm_filters.min_data_disk_count, false)) ||
        var.vm_filters.min_data_disk_count == null
      )
    ],

    #use the location info to ensure zone support and ultrassd support
    #if a zone is supplied provide sku's that include that zone in the location info.
    zones = [for sku, value in local.vm_map_location_conversion : sku if
      (
        (try(contains(toset(value[lower(var.location)].zones), tostring(var.vm_filters.location_zone)), false)) ||
        var.vm_filters.location_zone == null
      )
    ],

    UltraSSDAvailable = [for sku, value in local.vm_location_capabilities : sku if
      (
        (try(lower(value["UltraSSDAvailable"].value) == lower(tostring(var.vm_filters.location_ultrassd_support)), false)) ||
        var.vm_filters.location_ultrassd_support == null
      )
    ],

  } : {}
  vm_skus = length(local.vm_valid_skus) > 0 ? local.vm_valid_skus : ["no_valid_skus_found"]
  #get the intersection of all the capability lists as the list of skus matching all supplied conditions.
  vm_valid_skus = lower(var.resource_type) == "vm" ? setintersection(
    local.vm_per_element_valid_skus["CpuArchitectureType"],
    local.vm_per_element_valid_skus["AcceleratedNetworkingEnabled"],
    local.vm_per_element_valid_skus["EncryptionAtHostSupported"],
    local.vm_per_element_valid_skus["EphemeralOSDiskSupported"],
    local.vm_per_element_valid_skus["HibernationSupported"],
    local.vm_per_element_valid_skus["LowPriorityCapable"],
    local.vm_per_element_valid_skus["MemoryPreservingMaintenanceSupported"],
    local.vm_per_element_valid_skus["PremiumIO"],
    local.vm_per_element_valid_skus["RdmaEnabled"],
    local.vm_per_element_valid_skus["vCPUs_min"],
    local.vm_per_element_valid_skus["vCPUs_max"],
    local.vm_per_element_valid_skus["MemoryGB_min"],
    local.vm_per_element_valid_skus["MemoryGB_max"],
    local.vm_per_element_valid_skus["GPUs_min"],
    local.vm_per_element_valid_skus["GPUs_max"],
    local.vm_per_element_valid_skus["MaxNetworkInterfaces_min"],
    local.vm_per_element_valid_skus["MaxDataDiskCount_min"],
    local.vm_per_element_valid_skus["zones"],
    local.vm_per_element_valid_skus["UltraSSDAvailable"],
  ) : toset([])
}

#TODO: Can we randomly select using list value instead of a list index? (future improvement?)
resource "random_integer" "vm_deploy_sku" {
  max = length(local.vm_skus) - 1
  min = 0
}
