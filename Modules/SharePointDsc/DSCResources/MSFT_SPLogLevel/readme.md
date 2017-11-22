# Description

This resource is used to change the minimum severity of events captured in
the trace logs (ULS logs) and the Windows event logs. Settings can be changed
globally for all areas and categories (using the '*' character as the
wildcard), for all categories within an area, and for specific categories
within an area. Settings can be change to desired valid valures, or set to the
default by using the keyword 'default' as the trace level and event level.
You must specify a unique name for each insance of this resource in a configuration.
