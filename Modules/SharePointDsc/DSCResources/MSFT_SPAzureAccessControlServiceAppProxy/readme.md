# Description

**Type:** Distributed
**Requires CredSSP:** No

This resource is used to create a new service application proxy for the Azure
Control service application. It will identify an instance of the ACS service
application proxy through the display name. Currently the resource will
provision the app proxy if it does not yet exist, and will recreate the proxy
if the metadata service endpoint URI associated to the proxy does not match the
configuration.

The default value for the Ensure parameter is Present. When not specifying this
parameter, the service application proxy is provisioned.
