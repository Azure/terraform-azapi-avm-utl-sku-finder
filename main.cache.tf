locals {
  cache_map = {
    vm = local.vm_cache_map
  }
}

#generate a random suffix for use by the cache filename
resource "random_string" "name_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "local_file" "local_sku_cache" {
  count = var.cache_results ? (var.cache_storage_details == null ? 1 : 0) : 0

  filename = "${path.root}/${var.resource_type}-${var.local_cache_prefix}-${random_string.name_suffix.result}.cache"
  content  = jsonencode(local.cache_map["${var.resource_type}"])

  lifecycle {
    ignore_changes = [content] #this is a cache file, we don't want to update it when the content changes
  }
}

#rewrite this using azAPI? No obvious API call for this using AzAPI
resource "azurerm_storage_blob" "cache" {
  count = var.cache_results ? (var.cache_storage_details == null ? 0 : 1) : 0

  name                   = "${var.resource_type}-${var.cache_storage_details.storage_account_blob_prefix}-${random_string.name_suffix.result}.cache"
  storage_account_name   = var.cache_storage_details.storage_account_name
  storage_container_name = var.cache_storage_details.storage_account_blob_container_name
  type                   = "Block"
  source_content         = jsonencode(local.cache_map["${var.resource_type}"])

  lifecycle {
    ignore_changes = [source_content] #this is a cache file, we don't want to update it when the content changes
  }
}


