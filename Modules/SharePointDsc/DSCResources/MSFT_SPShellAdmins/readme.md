# Description

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

Notes:
1.) If a content database is created using the Central Admin, the farm account
is the owner of that content database in SQL Server. When this is true, you
cannot add it to the Shell Admins (common for AllContentDatabases parameter)
and the resource will throw an error. Workaround: Change database owner in SQL
