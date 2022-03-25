# Description

**Type:** Distributed
**Requires CredSSP:** No

This resource is used to work with SharePoint Property Bags at the farm level.
The account that runs this resource must be a farm administrator.

The Value parameter must be in string format, but with the ParameterType
parameter, you can specify of which data type the data in Value is: String,
Boolean or Int32. See the examples for more information.

The default value for the Ensure parameter is Present. When not specifying this
parameter, the property bag is configured.
