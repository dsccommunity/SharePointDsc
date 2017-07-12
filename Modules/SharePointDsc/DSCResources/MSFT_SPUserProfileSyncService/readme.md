# Description

This resource is responsible for ensuring that the user profile sync service
has been provisioned (Ensure = "Present") or is not running (Ensure =
"Absent") on the current server.

This resource requires that the FarmAccount is specified as the InstallAccount
parameter. It will throw an exception if this is not the case.

To allow successful provisioning the farm account must be in the local
administrators group, however it is not best practice to leave this account in
the Administrators group. Therefore this resource will add the FarmAccount
credential to the local administrators group at the beginning of the set method
and remove it again later on.

The default value for the Ensure parameter is Present. When not specifying this
parameter, the user profile sync service is provisioned.
