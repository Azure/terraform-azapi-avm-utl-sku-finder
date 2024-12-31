<!-- BEGIN_TF_DOCS -->
# Local Cache file example

This example demonstrates using the vm resource type with a few common filters to output a set of skus and sku\_list. It writes to a storage account blob cache file to demonstrate the use of the cache to avoid sku changes when the valid sku list changes.

```hcl
terraform {
  required_version = "~> 1.9"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.115, < 5.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  features {}
}

locals {
  location = "canadacentral"
}

module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.3.0"

  availability_zones_filter = true
}

resource "random_integer" "zone_index" {
  max = length(module.regions.regions_by_name[local.location].zones)
  min = 1
}

module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.0"
}

resource "azurerm_resource_group" "this" {
  location = local.location
  name     = module.naming.resource_group.name_unique
}

# Get current IP address for use in storage firewall rules
data "http" "ip" {
  url = "https://api.ipify.org/"
  retry {
    attempts     = 5
    max_delay_ms = 1000
    min_delay_ms = 500
  }
}


# This is a workaround for the limitation of the storage account firewall rules that require a /30 CIDR block
# Do not do this in production, this is just for the sake of the example
locals {
  ip_cidr  = "${join(".", concat(slice(local.ip_split, 0, 3), [tostring(((tonumber(local.ip_split[3])) - (tonumber(local.ip_split[3]) % 4)))]))}/30"
  ip_split = split(".", data.http.ip.response_body)
}

data "azurerm_client_config" "current" {}

module "this_storage_account" {

  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "0.2.9"

  account_replication_type      = "ZRS"
  account_tier                  = "Standard"
  account_kind                  = "StorageV2"
  location                      = azurerm_resource_group.this.location
  name                          = module.naming.storage_account.name_unique
  https_traffic_only_enabled    = true
  resource_group_name           = azurerm_resource_group.this.name
  min_tls_version               = "TLS1_2"
  shared_access_key_enabled     = true
  public_network_access_enabled = true

  blob_properties = {
    versioning_enabled = true
  }

  role_assignments = {
    role_assignment_1 = {
      role_definition_id_or_name       = "Storage Blob Data Owner"
      principal_id                     = data.azurerm_client_config.current.object_id
      skip_service_principal_aad_check = false
    },
    role_assignment_2 = {
      role_definition_id_or_name       = "Owner"
      principal_id                     = data.azurerm_client_config.current.object_id
      skip_service_principal_aad_check = false
    },
  }

  network_rules = {
    bypass         = ["AzureServices"]
    default_action = "Deny"
    ip_rules       = [local.ip_cidr]
  }

  containers = {
    sku_cache_container = {
      name = "cache-container"
    }
  }
}


module "vm_skus" {
  source = "../.."

  enable_telemetry = var.enable_telemetry
  location         = azurerm_resource_group.this.location
  resource_type    = "vm"
  vm_filters = {
    accelerated_networking_enabled = true
    cpu_architecture_type          = "x64"
    min_vcpus                      = 2
    max_vcpus                      = 4
    encryption_at_host_supported   = true
    min_network_interfaces         = 2
    location_zone                  = random_integer.zone_index.result
  }

  cache_results = true
  cache_storage_details = {
    storage_account_resource_group_name = azurerm_resource_group.this.name
    storage_account_name                = module.this_storage_account.name
    storage_account_blob_container_name = split("/", module.this_storage_account.containers["sku_cache_container"].id)[(length(split("/", module.this_storage_account.containers["sku_cache_container"].id))) - 1]
    storage_account_blob_prefix         = "remote-stg"
  }

  depends_on = [random_integer.zone_index]
}

output "sku" {
  value = module.vm_skus.sku
}

output "sku_list" {
  value = module.vm_skus.sku_list
}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (~> 1.9)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>= 3.115, < 5.0)

- <a name="requirement_http"></a> [http](#requirement\_http) (~> 3.4)

- <a name="requirement_random"></a> [random](#requirement\_random) (~> 3.6)

## Resources

The following resources are used by this module:

- [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [random_integer.zone_index](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/integer) (resource)
- [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)
- [http_http.ip](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

No required inputs.

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry)

Description: This variable controls whether or not telemetry is enabled for the module.  
For more information see <https://aka.ms/avm/telemetryinfo>.  
If it is set to false, then no telemetry will be collected.

Type: `bool`

Default: `true`

## Outputs

The following outputs are exported:

### <a name="output_sku"></a> [sku](#output\_sku)

Description: n/a

### <a name="output_sku_list"></a> [sku\_list](#output\_sku\_list)

Description: n/a

## Modules

The following Modules are called:

### <a name="module_naming"></a> [naming](#module\_naming)

Source: Azure/naming/azurerm

Version: 0.4.0

### <a name="module_regions"></a> [regions](#module\_regions)

Source: Azure/avm-utl-regions/azurerm

Version: 0.3.0

### <a name="module_this_storage_account"></a> [this\_storage\_account](#module\_this\_storage\_account)

Source: Azure/avm-res-storage-storageaccount/azurerm

Version: 0.2.9

### <a name="module_vm_skus"></a> [vm\_skus](#module\_vm\_skus)

Source: ../..

Version:

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->