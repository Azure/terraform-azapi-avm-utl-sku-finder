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
  count = var.cache_results ? 1 : 0

  filename = "${path.root}/${var.resource_type}-${var.local_cache_prefix}-${random_string.name_suffix.result}.cache"
  content  = jsonencode(local.cache_map[var.resource_type])

  lifecycle {
    ignore_changes = [content] #this is a cache file, we don't want to update it when the content changes
  }
}
