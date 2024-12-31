<!-- BEGIN_TF_DOCS -->
# terraform-azapi-avm-utl-sku-finder

This AVM utility module finds sku's that match a set of filter conditions. It is intended to assist with situations where your subscription is restricted for specific sku's and you need to find an available sku that meets your target technical criteria.  

The module returns a randomly selected sku and the full list of sku's that it was selected from. It has an initial default filter that avoids sku's with any restrictions defined or without any capabilities returned by the sku API's.

Because available sku's can vary from day to day for some subscriptions, the module also contains the ability to cache the initial output either as a local file or a storage account blob. This is to retain idempotency for other Terraform modules or resources that consume sku's from the module.

>Note: If you are using a zone value that is only known after apply, then ensure that you set a depends on block for the resource generating the zone. This is to handle an error where the sku map doesn't form properly due to the inability to determine the zone type. See the examples for a demonstration of this.

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (~> 1.10)

- <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) (~> 2.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>= 3.115, < 5.0)

- <a name="requirement_local"></a> [local](#requirement\_local) (~> 2.5)

- <a name="requirement_modtm"></a> [modtm](#requirement\_modtm) (~> 0.3)

- <a name="requirement_random"></a> [random](#requirement\_random) (~> 3.6)

## Resources

The following resources are used by this module:

- [azurerm_storage_blob.cache](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_blob) (resource)
- [local_file.local_sku_cache](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) (resource)
- [modtm_telemetry.telemetry](https://registry.terraform.io/providers/azure/modtm/latest/docs/resources/telemetry) (resource)
- [random_integer.vm_deploy_sku](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/integer) (resource)
- [random_string.name_suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) (resource)
- [random_uuid.telemetry](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/uuid) (resource)
- [azapi_resource_list.vm](https://registry.terraform.io/providers/azure/azapi/latest/docs/data-sources/resource_list) (data source)
- [azurerm_client_config.telemetry](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)
- [azurerm_subscription.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subscription) (data source)
- [modtm_module_source.telemetry](https://registry.terraform.io/providers/azure/modtm/latest/docs/data-sources/module_source) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_location"></a> [location](#input\_location)

Description: Azure region where the target skus will be deployed. This is required as the initial api query is filtered by location for speed.

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_cache_results"></a> [cache\_results](#input\_cache\_results)

Description: Do you want to write the single random sku output to a cache file? This is to ensure idempotency when re-running the module as sku criteria change over time.

Type: `bool`

Default: `false`

### <a name="input_cache_storage_details"></a> [cache\_storage\_details](#input\_cache\_storage\_details)

Description: This object is used to define the storage account and container where the cache file will be stored.

- `storage_account_resource_group_name` - The name of the resource group where the storage account is located.
- `storage_account_name` - The name of the storage account where the cache file will be stored.
- `storage_account_blob_container_name` - The name of the container where the cache file will be stored.
- `storage_account_blob_prefix` - The prefix to be used for the cache file blob.

Type:

```hcl
object({
    storage_account_resource_group_name = string
    storage_account_name                = string
    storage_account_blob_container_name = string
    storage_account_blob_prefix         = string
  })
```

Default: `null`

### <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry)

Description: This variable controls whether or not telemetry is enabled for the module.  
For more information see <https://aka.ms/avm/telemetryinfo>.  
If it is set to false, then no telemetry will be collected.

Type: `bool`

Default: `true`

### <a name="input_local_cache_prefix"></a> [local\_cache\_prefix](#input\_local\_cache\_prefix)

Description: If caching locally, this prefix will be used to help identify the cache file in the event that the module is called multiple times.

Type: `string`

Default: `"local"`

### <a name="input_resource_type"></a> [resource\_type](#input\_resource\_type)

Description: The resource type you want a sku for.  Currently only supports VM's, but additional resource types will be added over time.

Type: `string`

Default: `"vm"`

### <a name="input_vm_filters"></a> [vm\_filters](#input\_vm\_filters)

Description: This object is used to filter the available skus based on the criteria you provide.

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

Type:

```hcl
object({
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
```

Default: `{}`

## Outputs

The following outputs are exported:

### <a name="output_resource_id"></a> [resource\_id](#output\_resource\_id)

Description: The resource id of the resource. This is actually a repeat of the sku output to make the linter happy.

### <a name="output_sku"></a> [sku](#output\_sku)

Description: The randomly selected sku returned from the filtered list of skus.

### <a name="output_sku_list"></a> [sku\_list](#output\_sku\_list)

Description: The list of skus returned from the filtered list of skus.

## Modules

No modules.

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->