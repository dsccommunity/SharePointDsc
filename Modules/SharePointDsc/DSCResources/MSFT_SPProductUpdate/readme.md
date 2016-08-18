**Description**

This resource is used to perform the update step of installing SharePoint updates, like Cumulative Updates and Service Packs.
The SetupFile parameter should point to the update file.
The ShutdownServices parameter is used to indicate if some services have to be stopped before installation of the update. 
The BinaryInstallDays and BinaryInstallTime parameters specify a window in which the update can be installed.
This module requires the Configuration Wizard resource to fully complete the installation of the update, which can be done through the use of [SPConfigWizard](SPConfigWizard).
