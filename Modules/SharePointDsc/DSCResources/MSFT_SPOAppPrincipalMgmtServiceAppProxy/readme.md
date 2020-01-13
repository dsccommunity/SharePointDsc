# Description

**Type:** Distributed
**Requires CredSSP:** No

This resource is used to create a SharePoint Online management Application Proxy.
This is used by for example hybrid search. It will identify an instance of the
SPO management apllication proxy through the display name. Currently the
resource will provision the app proxy if it does not yet exist, and will
recreate the proxy if the Online Tenant URI associated to the proxy does not
match the configuration.

The default value for the Ensure parameter is Present. When not specifying this
parameter, the service application is provisioned.
