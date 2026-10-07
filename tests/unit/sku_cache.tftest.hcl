mock_provider "azapi" {
  mock_data "azapi_client_config" {
    defaults = {
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
    }
  }

  mock_data "azapi_resource_list" {
    defaults = {
      output = {
        value = [
          {
            name         = "Standard_D2s_v3"
            resourceType = "virtualMachines"
            restrictions = []
            capabilities = [
              { name = "CpuArchitectureType", value = "x64" },
              { name = "vCPUs", value = "2" },
              { name = "MemoryGB", value = "8" },
              { name = "MaxNetworkInterfaces", value = "2" },
            ]
            locationInfo = [
              {
                location = "canadacentral"
                zones    = ["1", "2", "3"]
                zoneDetails = [
                  {
                    capabilities = [
                      { name = "UltraSSDAvailable", value = "True" },
                    ]
                  },
                ]
              },
            ]
          },
        ]
      }
    }
  }
}

mock_provider "local" {}

mock_provider "modtm" {}

mock_provider "random" {
  # Pin the selection so the asserted sku is deterministic rather than a random index.
  mock_resource "random_integer" {
    defaults = {
      result = 0
    }
  }
}

variables {
  location = "canadacentral"
}

run "returns_the_matching_sku_when_caching_is_disabled" {
  command = apply

  variables {
    cache_results = false
  }

  assert {
    condition     = output.sku == "Standard_D2s_v3"
    error_message = "The module must return the sku that matches the supplied filters."
  }

  assert {
    condition     = contains(output.sku_list, "Standard_D2s_v3")
    error_message = "The module must return the filtered sku list."
  }
}

run "returns_the_matching_sku_from_the_local_cache_file" {
  command = apply

  variables {
    cache_results = true
  }

  assert {
    condition     = output.sku == "Standard_D2s_v3"
    error_message = "With cache_results enabled the sku must be read back from the local cache file."
  }

  assert {
    condition     = contains(output.sku_list, "Standard_D2s_v3")
    error_message = "With cache_results enabled the sku_list must be read back from the local cache file."
  }
}
