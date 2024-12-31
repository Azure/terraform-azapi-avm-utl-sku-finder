# terraform-azapi-avm-utl-sku-finder

This AVM utility module finds sku's that match a set of filter conditions. It is intended to assist with situations where your subscription is restricted for specific sku's and you need to find an available sku that meets your target technical criteria.  

The module returns a randomly selected sku and the full list of sku's that it was selected from. It has an initial default filter that avoids sku's with any restrictions defined or without any capabilities returned by the sku API's.

Because available sku's can vary from day to day for some subscriptions, the module also contains the ability to cache the initial output either as a local file or a storage account blob. This is to retain idempotency for other Terraform modules or resources that consume sku's from the module.

>Note: If you are using a zone value that is only known after apply, then ensure that you set a depends on block for the resource generating the zone. This is to handle an error where the sku map doesn't form properly due to the inability to determine the zone type. See the examples for a demonstration of this.

