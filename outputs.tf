output "sku" {
  description = "The randomly selected sku returned from the filtered list of skus."
  value       = local.output_map[var.resource_type].sku
}

output "sku_list" {
  description = "The list of skus returned from the filtered list of skus."
  value       = local.output_map[var.resource_type].sku_list
}
