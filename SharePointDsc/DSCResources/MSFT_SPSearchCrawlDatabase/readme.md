# Description

**Type:** Distributed
**Requires CredSSP:** No

This resource is responsible for provisioning the search service application.
The current version lets you specify the database name and server, as well as
the application pool. If the application pool is changed the DSC resource will
set it back as per what is set in the resource. The database name parameter is
used as the prefix for all search databases (so you will end up with one for
the admin database which matches the name, and then
"_analyticsreportingstore", "_crawlstore" and "_linkstore" databases as well).

The default value for the Ensure parameter is Present. When not specifying this
parameter, the service application is provisioned.

For more information about the Deletion Policy settings, check the following
article:
https://docs.microsoft.com/en-us/previous-versions/office/sharepoint-server-2010/hh127009(v=office.14)?redirectedfrom=MSDN

**NOTE:** Don't forget to configure a Search topology using the SPSearchTopology
resource!

**NOTE2:** The resource is also able to add the Farm account as db_owner to all
Search databases, to prevent the issue described here:
https://www.techmikael.com/2014/10/caution-if-you-have-used.html
Use the FixFarmAccountPermissions parameter to implement this fix (default
$true if not specified).
