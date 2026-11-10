terraform {
  required_version = "~> 1.9"

  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

locals {
  deployment_region = "canadacentral"
}

module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.13.2"

  location               = local.deployment_region
  enable_telemetry       = var.enable_telemetry
  has_availability_zones = true
  is_recommended         = true
}

resource "random_integer" "zone_index" {
  max = length(module.regions.regions_by_name[local.deployment_region].zones)
  min = 1
}

module "vm_skus" {
  source = "../.."

  location           = "canadacentral"
  cache_results      = true
  enable_telemetry   = var.enable_telemetry
  local_cache_prefix = "example"
  resource_type      = "vm"
  vm_filters = {
    accelerated_networking_enabled = true
    cpu_architecture_type          = "x64"
    min_vcpus                      = 2
    max_vcpus                      = 2
    encryption_at_host_supported   = true
    min_network_interfaces         = 2
    location_zone                  = random_integer.zone_index.result
  }

  depends_on = [random_integer.zone_index]
}
