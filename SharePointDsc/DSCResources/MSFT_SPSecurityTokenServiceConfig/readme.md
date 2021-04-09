# Description

**Type:** Distributed
**Requires CredSSP:** No

This resource is responsible for configuring the Security Token Service within
the local SharePoint farm. Using Ensure equals to Absent is not supported.
This resource can only apply configuration, not ensure they don't exist.

This resource is also able to set the properties FormsTokenLifetime, WindowsTokenLifetime and LogonTokenCacheExpirationWindow.
It checks for values leading to "The context has expired and can no longer be used." errors.
The value for LogonTokenCacheExpirationWindow must be higher than the values for FormsTokenLifetime and WindowsTokenLifetime,
it will return an error if not.
