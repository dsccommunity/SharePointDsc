# Description

This resource will provision an instance of the user profile service to the
farm. It creates the required databases using the parameters that are passed
in to it (although these are only used during the initial provisioning).

The specified InstallAccount or PSDSCRunAsCredential shouldn't be the Farm Account.
The resource will throw an error when it is. However, the FarmAccount parameter
should be the Farm Account. The resource will throw an error if it is not. This is
done to ensure that the databases are created with the correct schema owners and
allow the user profile sync service to operate correctly. The Farm Account is
temporarily granted local Administrator permissions.

The default value for the Ensure parameter is Present. When not specifying this
parameter, the service application is provisioned.

NOTE:
Due to the fact that SharePoint requires certain User Profile components to be
provisioned as the Farm account, do this resource and SPUserProfileSyncService
require the Farm account to be specified in the FarmAccount parameter.
This does however mean that CredSSP is required, which has some security
implications. More information about these risks can be found at:
http://www.powershellmagazine.com/2014/03/06/accidental-sabotage-beware-of-credssp/
