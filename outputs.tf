output "sku" {
  value = local.output_map["${var.resource_type}"].sku
}

output "sku_list" {
  value = local.output_map["${var.resource_type}"].sku_list
}
