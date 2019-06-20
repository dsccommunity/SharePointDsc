# Description

**Type:** Common
**Requires CredSSP:** No

This resource is used to install the SharePoint binaries. The BinaryDir
parameter should point to the path that setup.exe is located (not to setup.exe
itself). The ProductKey parameter is used to inject in to the configuration
file and validate the license key during the installation process. This module
depends on the prerequisites already being installed, which can be done

NOTE:
This resource only supports SharePoint Server. SharePoint Foundation
is not supported. For examples to install SharePoint Foundation using DSC, see:
https://github.com/PowerShell/SharePointDsc/wiki/SPInstall (Example 3)

NOTE 2:
When files are downloaded from the Internet, a Zone.Identifier alternate data
stream is added to indicate that the file is potentially from an unsafe source.
To use these files, make sure you first unblock them using Unblock-File.
SPInstall will throw an error when it detects the file is blocked.

## Multilingual support

Where possible, resources in SharePointDsc have been written in a way that
they should support working with multiple language packs for multilingual
deployments. However due to constraints in how we set up and install the
product, only English ISOs are supported for installing SharePoint.
