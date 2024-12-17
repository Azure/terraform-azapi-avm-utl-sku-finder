output "resource_id" {
  description = "The resource id of the resource. This is actually a repeat of the sku output to make the linter happy."
  value       = local.output_map[var.resource_type].sku
}

output "sku" {
  description = "The randomly selected sku returned from the filtered list of skus."
  value       = local.output_map[var.resource_type].sku
}

output "sku_list" {
  description = "The list of skus returned from the filtered list of skus."
  value       = local.output_map[var.resource_type].sku_list
}
