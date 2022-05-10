# Description

**Type:** Distributed
**Requires CredSSP:** No

This resource is used to manage the users with Shell Admin permissions. There
are a number of approaches to how this can be implemented. The "Members"
property will set a specific list of members for the group, making sure that
every user/group in the list is in the group and all others that are members
and who are not in this list will be removed. The "MembersToInclude" and
"MembersToExclude" properties will allow you to control a specific set of
users to add or remove, without changing any other members that are in the
group already that may not be specified here, allowing for some manual
management outside of this configuration resource. The "ContentDatabases" and
"AllContentDatabases" properties will allow you to control the permissions on
Content Databases.

Requirements:

* At least one of the Members, MemberToInclude or MembersToExclude properties
  needs to  be specified.
* Do not combine the Members property with the MemberToInclude and
  MembersToExclude  properties.
* Do not combine the ContentDatabase property with the AllContentDatabases
  property.

Required permissions:

The documentation of the Shell Admin cmdlets states that you need the following
permissions to successfully run this resource:
> "When you run this cmdlet to add a user to the SharePoint_Shell_Access role,
you must have membership in the securityadmin fixed server role on the SQL
Server instance, membership in the db_owner fixed database role on all
affected databases, and local administrative permission on the local computer."

and
> "This cmdlet is intended only to be used with a database that uses Windows
authentication. There is no need to use this cmdlet for databases that use SQL
authentication; in fact, doing so may result in an error message."

*Source:* https://docs.microsoft.com/en-us/powershell/module/sharepoint-server/add-spshelladmin?view=sharepoint-ps

**Notes:**

- In some instances the Farm account has been configured as the owner of a
SharePoint database. When that is the case, SharePoint is unable to add the Farm
account as a Shell Admin. We have implemented a workaround for this issue,
but it can mean some warnings are shown. The workaround for this issue is to change
database owner in SQL and grant the Farm account permissions to the database
directly and add the db_owner database role
