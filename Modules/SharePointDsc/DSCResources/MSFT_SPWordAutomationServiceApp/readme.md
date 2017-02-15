# Description

The resource is able to provision, unprovision and configure the Word
Automation Service Application. All settings that you can configure on the
Service Application administration page are configurable using this resource.

Important:
When you specify Ensure=Present, the Application Pool and DatabaseName
parameters are required. When you specify Ensure=Absent, no other parameters
are allowed (with the exception of Name, InstallAccount or
PsDscRunAsCredential).
