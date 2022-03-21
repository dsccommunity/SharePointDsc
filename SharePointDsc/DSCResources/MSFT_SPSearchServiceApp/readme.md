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

**NOTE:** Use 'ProvisionDefaultTopology = $true' parameter to provision default search topology. When this parameter is defined
and value is TRUE then topology is created as below:

1. First we check are there any servers having Search or ApplicationWithSearch role. If there are then all search components are
provisioned to all these servers

2. If no Search or ApplicationWithSearch role servers exist then we check are there servers having Custom role. If yes then all 
search server components are provisioned to one (1) server having Custom role

3. If no servers exist having roles defined in 1 and 2 then we check is this SingleServer or SingleServerFarm deployment and if yes
the all search server components are provisioned to that single server

If you do not want to provision default topology then you need to define search topology using the SPSearchTopology resource!

**NOTE2:** The resource is also able to add the Farm account as db_owner to all
Search databases, to prevent the issue described here:
https://www.techmikael.com/2014/10/caution-if-you-have-used.html
Use the FixFarmAccountPermissions parameter to implement this fix (default
$true if not specified).
