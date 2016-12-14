# Description

This resource will allow specifying which SQL Server AlwaysOn Availability
group a resource should be in. This resource does not configure the
Availability Groups on SQL Server, they must already exist. It simply adds
the specified database to the group.

You can add a single database name by specifying the database name, or
multiple databases by specifying wildcards. For example:
SP_Content* or *Content*

Important:
This resource requires the April 2014 CU to be installed. The required
cmdlets have been added in this CU: http://support.microsoft.com/kb/2880551
