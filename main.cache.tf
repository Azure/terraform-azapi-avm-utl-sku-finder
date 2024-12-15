




#generate a random suffix for use by the cache filename
resource "random_string" "name_suffix" {
  length  = 8
  special = false
  upper   = false
}
#TODO: replace these with versions that generate based on resource_Type
resource "random_integer" "deploy_sku" {
  max = length(local.vm_valid_skus) - 1
  min = 0
}

locals {
  vm_single_sku_output = var.cache_results ? (var.cache_storage_details == null ? jsondecode(local_file.local_sku_cache[0].content).sku :  jsondecode(azurerm_storage_blob.cache[0].source_content).sku ) : try(tolist(local.vm_valid_skus)[random_integer.deploy_sku.result], "no_current_valid_skus")
  vm_sku_list_output = var.cache_results ? (var.cache_storage_details == null ? jsondecode(local_file.local_sku_cache[0].content).sku_list :  jsondecode(azurerm_storage_blob.cache[0].source_content).sku_list ) : local.vm_valid_skus
}

/*
resource "local_file" "local_sku_cache" {
  count = var.cache_results ? (var.cache_storage_details == null ? 1 : 0) : 0

  filename = "${path.module}/sku-cache-${random_string.name_suffix.result}.cache"
  content  = jsonencode(local.cache_map)

  lifecycle {
    ignore_changes = [content]
  }
}

#rewrite this using azAPI?
resource "azurerm_storage_blob" "cache" {
  count = var.cache_results ? (var.cache_storage_details == null ? 0 : 1) : 0

  name                   = "${var.cache_storage_details.storage_account_blob_prefix}-${random_string.name_suffix.result}.cache"
  storage_account_name   = var.cache_storage_details.storage_account_name
  storage_container_name = var.cache_storage_details.storage_account_blob_container_name
  type                   = "Block"
  source_content         = jsonencode(local.cache_map)


  lifecycle {
    ignore_changes = [source_content]
  }
}
*/

