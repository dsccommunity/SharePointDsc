# Description

This resource will be responsible for joining a server to an existing
SharePoint farm. To create a new farm use the SPCreateFarm resource on a
different server to begin with, and then pass the same database server and
configuration database name parameters to the additional servers using this
resource. After the server has joined the farm, the process will wait for 5
minutes to allow farm specific configuration to take place on the server,
before allowing further DSC configuration to take place.
