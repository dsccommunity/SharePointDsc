# Description

This resource will provision an instance of the user profile service to the
farm. It creates the required databases using the parameters that are passed
in to it (although these are only used during the initial provisioning).

The specified InstallAccount or PSDSCRunAsCredential has to be the Farm Account
This is done to ensure that the databases are created with the correct schema
owners and allow the user profile sync service to operate correctly.

The default value for the Ensure parameter is Present. When not specifying this
parameter, the service application is provisioned.
