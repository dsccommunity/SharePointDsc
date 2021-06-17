# Description

**Type:** Distributed
**Requires CredSSP:** No

This resource is used to specify if a specific service should be provisioned
(Ensure = "Present") or deprovisioned (Ensure = "Absent") in the MinRole
configuration of the farm. The name is the display name of the service as
shown in the "Services in Farm" page in Central Admin:
http://[central_admin_url]/_admin/FarmServices.aspx

The default value for the Ensure parameter is Present. When not specifying this
parameter, the service instance is started.
