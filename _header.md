# terraform-azapi-avm-utl-sku-finder

This AVM utility module finds sku's that match a set of filter conditions. It is intended to assist with situations where your subscription is restricted for specific sku's and you need to find an available sku that meets your target technical criteria.  

The module returns a randomly selected sku and the full list of sku's that it was selected from. It has an initial default filter that avoids sku's with any restrictions defined or without any capabilities returned by the sku API's.

Because available sku's can vary from day to day for some subscriptions, the module can cache the initial output as a local file. This is to retain idempotency for other Terraform modules or resources that consume sku's from the module.

>Note: The cached sku is held in Terraform state, and the cache file acts as the marker that keeps it pinned. If the cache file is lost the module recreates it and selects a new sku. This happens whenever the root module directory is not persisted between runs, which is the normal case on a CI runner, so set `cache_results` expecting the pin to hold only where both the state *and* the cache file survive.

>Note: If you are using a zone value that is only known after apply, then ensure that you set a depends on block for the resource generating the zone. This is to handle an error where the sku map doesn't form properly due to the inability to determine the zone type. See the examples for a demonstration of this.

## Upgrading to v0.4.0

v0.4.0 removes the storage account blob cache. The `cache_storage_details` input no longer exists, and the module no longer requires the `azurerm` provider for it.

If you did not set `cache_storage_details`, no action is required.

If you did set it, remove the input before upgrading. On the next apply Terraform destroys the cache blob and, where `cache_results` is still `true`, writes a local cache file instead. The previously pinned sku is **not** carried across, so the module selects a new sku and any resource consuming that output may be replaced. To keep the existing sku, read it from the current cache blob first and pass that value directly to the consuming resource instead of the module output.

