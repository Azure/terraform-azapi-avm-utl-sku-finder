### get the working subscription details
data "azurerm_subscription" "current" {}

locals {
  output_map = merge(local.vm_output_map) #add other resource type output maps here
}
