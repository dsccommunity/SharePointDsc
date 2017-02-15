# Description

This resource is used to manage the sharing security settings of a specific
service application. There are a number of approaches to how this can be
implemented. Firstly you can set permissions for the app administrators, or
for the sharing permission by specifying the SecurityType attribute. These
options correlate to the buttons seen in the ribbon on the "manage service
applications" page in Central Administration after you select a specific
service app. The "Members" property will set a specific list of members for
the service app, making sure that every user/group in the list is in the group
and all others that are members and who are not in this list will be removed.
The "MembersToInclude" and "MembersToExclude" properties will allow you to
control a specific set of users to add or remove, without changing any other
members that are in the group already that may not be specified here, allowing
