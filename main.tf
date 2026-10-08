### get the working subscription details
data "azapi_client_config" "current" {}

locals {
  output_map = merge(local.vm_output_map) #add other resource type output maps here
}
