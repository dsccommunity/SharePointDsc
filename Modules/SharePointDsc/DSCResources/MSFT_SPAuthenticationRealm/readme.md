# Description

**Type:** Distributed
**Requires CredSSP:** No

This resource is used to set the authentication realm for a farm.
By default the authentication realm for a new farm installation
is the same as the farm id.

Note:

SharePoint automatically converts the realm to lower case ASCII printable characters.
The specified authentication realm must therefore conform to this for the test
method to be able to detect a correct configuration.
