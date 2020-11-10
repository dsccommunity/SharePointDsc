# Description

**Type:** Distributed
**Requires CredSSP:** No

This resource will provision a SPWeb based on the settings that are passed
through. These settings map to the New-SPWeb cmdlet and accept the same values

The default value for the Ensure parameter is Present. When not specifying this
parameter, the web is created.

NOTE:
Since subsites/webs can be created/deleted by site collection owners it is
possible that using this resource results in a conflict between the owner
and DSC. Therefore be careful using this resource.
