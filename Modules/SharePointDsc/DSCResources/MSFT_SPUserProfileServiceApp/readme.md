# Description

This resource will provision an instance of the user profile service to the
farm. It creates the required databases using the parameters that are passed
in to it (although these are only used during the initial provisioning).

The specified InstallAccount or PSDSCRunAsCredential shouldn't be the Farm Account.
The resource will throw an error when it is. The FarmAccount parameter should be
the Farm Account. The resource will throw an error if it is not. This is done to
ensure that the databases are created with the correct schema owners and allow the
user profile sync service to operate correctly. The Farm Account is temporarily
granted local Administrator permissions.

The default value for the Ensure parameter is Present. When not specifying this
parameter, the service application is provisioned.
