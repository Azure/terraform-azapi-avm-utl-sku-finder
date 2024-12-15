output "resource" {
  description = "This is a repeat of the sku value to satisfy the AVM spec requirement for a resource output."
  value       = local.vm_single_sku_output
}

output "resource_id" {
  description = "This is a repeat of the sku value to satisfy the AVM spec requirement for a resource_id output."
  #value       = try(tolist(local.valid_skus)[random_integer.deploy_sku.result], "no_current_valid_skus")
  value = local.vm_single_sku_output
}

output "sku" {
  description = "The sku value generated by the sku selector tool"
  value       = local.vm_single_sku_output
}

output "sku_list" {
    description = "The list of sku's using the current subscription, and the current filters"
    value = local.vm_sku_list_output
}

