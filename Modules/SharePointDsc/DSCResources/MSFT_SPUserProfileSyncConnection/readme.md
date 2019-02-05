# Description

**Type:** Distributed
**Requires CredSSP:** No

This resource will ensure a specifc user profile sync connection
is in place and that it is configured accordingly to its definition

This resource currently supports AD only.

Force only works with SharePoint 2013. For SharePoint 2016/2019
the resource is not able to remove existing OUs.
You will have to use the ExcludedOUs for this. This means you need
to know which OUs to remove. If any extra OUs exists after the
configuration has run the test method will report the resource not
in desired state.
