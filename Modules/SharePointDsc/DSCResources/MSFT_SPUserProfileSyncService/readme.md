# Description

This resource is responsible for ensuring that the user profile sync service
has been provisioned (Ensure = "Present") or is not running (Ensure =
"Absent") on the current server.

The specified InstallAccount or PSDSCRunAsCredential shouldn't be the Farm Account.
The resource will throw an error when it is. However, the FarmAccount parameter
should be the Farm Account. The resource will throw an error if it is not. This is
done to ensure that the databases are created with the correct schema owners and
allow the user profile sync service to operate correctly.

To allow successful provisioning, the farm account must be in the local
administrators group, however it is not best practice to leave this account in
the Administrators group. Therefore this resource will add the FarmAccount
credential to the local administrators group at the beginning of the set method
and remove it again later on.

The default value for the Ensure parameter is Present. When not specifying this
parameter, the user profile sync service is provisioned.

NOTE:
Due to the fact that SharePoint requires certain User Profile components to be
provisioned as the Farm account, do this resource and SPUserProfileServiceApp
require the Farm account to be specified in the FarmAccount parameter.
This does however mean that CredSSP is required, which has some security
implications. More information about these risks can be found at:
http://www.powershellmagazine.com/2014/03/06/accidental-sabotage-beware-of-credssp/
