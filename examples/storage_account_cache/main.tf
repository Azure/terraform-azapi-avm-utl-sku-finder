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
