# Description

**Type:** Common
**Requires CredSSP:** No

This resource is used to perform the update step of installing SharePoint
updates, like Cumulative Updates and Service Packs. The SetupFile parameter
should point to the update file. The ShutdownServices parameter is used to
indicate if some services (Timer, Search and IIS services) have to be stopped
before installation of the update. This will speed up the installation. The
BinaryInstallDays and BinaryInstallTime parameters specify a window in which
the update can be installed. This module requires the Configuration Wizard
resource to fully complete the installation of the update, which can be done
through the use of SPConfigWizard.

NOTE:
When files are downloaded from the Internet, a Zone.Identifier alternate data
stream is added to indicate that the file is potentially from an unsafe source.
To use these files, make sure you first unblock them using Unblock-File.
SPProductUpdate will throw an error when it detects the file is blocked.

IMPORTANT:
Since v3.3, this resource no longer relies on the farm being present to check
the installed patches. This means it is now possible to deploy updates during
the installation of SharePoint:

1. Install the SharePoint Binaries (SPInstall)
2. (Optional) Install SharePoint Language Pack(s) Binaries
   (SPInstallLanguagePack)
3. Install Cumulative Updates (SPProductUpdate)
4. Create SPFarm (SPFarm)
