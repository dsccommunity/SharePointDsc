# Description

**Type:** Distributed
**Requires CredSSP:** No

The resource is able to provision, unprovision and configure the Word
Automation Service Application. All settings that you can configure on the
Service Application administration page are configurable using this resource.

Important:
When you specify Ensure=Present, the Application Pool and DatabaseName
parameters are required. When you specify Ensure=Absent, no other parameters
are allowed (with the exception of Name, PsDscRunAsCredential).

The default value for the Ensure parameter is Present. When not specifying this
parameter, the service application is provisioned.

NOTE:
If you don't specify the AddToDefault parameter, the new Word Automation
service application won't be added to the default proxy group.
Please use "AddToDefault = $true" to make sure it is added to the default
proxy group.
