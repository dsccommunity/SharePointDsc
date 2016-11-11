# Description

This resource is responsible for ensuring that the user profile sync service
has been provisioned (Ensure = "Present") or is not running (Ensure =
"Absent") on the current server. This resource uses the InstallAccount to
validate the current state only, the set method which will do the provisioning
uses the FarmAccount to do the actual work - this means that CredSSP
authentication will need to be permitted to allow a connection to the local
server. To allow successful provisioning the farm account must be in the local
administrators group, however it is not best practice to leave this account in
the Administrators group. Therefore this resource will add the FarmAccount
credential to the local administrators group at the beginning of the set
