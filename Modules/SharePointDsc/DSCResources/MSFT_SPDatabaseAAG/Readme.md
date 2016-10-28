**Description**

This resource will allow specifying which SQL Server AlwaysOn Availability group a 
resource should be in. This resource does not configure the Availability Groups on 
SQL Server, they must already exist. It simply adds the specified database to the group.

You can add a single database name by specifying the database name, or multiple databases
by specifying a common part of the database name.
