terraform {
  required_version = "~> 1.9"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.115, < 5.0"
    }
  }
}

provider "azurerm" {
  features {}
}

locals {
  deployment_region = "canadacentral"
}

module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.3.0"

  availability_zones_filter = true
}

resource "random_integer" "zone_index" {
  max = length(module.regions.regions_by_name[local.deployment_region].zones)
  min = 1
}

module "vm_skus" {
  source = "../.."

  enable_telemetry = var.enable_telemetry
  location         = "canadacentral"
  resource_type    = "vm"
  vm_filters = {
    accelerated_networking_enabled = true
    cpu_architecture_type          = "x64"
    min_vcpus                      = 2
    max_vcpus                      = 2
    encryption_at_host_supported   = true
    min_network_interfaces         = 2
    location_zone                  = random_integer.zone_index.result
  }

  cache_results      = true
  local_cache_prefix = "example"

  depends_on = [random_integer.zone_index]
}

output "sku" {
  value = module.vm_skus.sku
}

output "sku_list" {
  value = module.vm_skus.sku_list
}
