When working with SharePoint servers with PowerShell DSC, there are a number of other DSC modules which contain useful resources which can further assist with the automation of your environments.

## xWebAdministration

Available at: [https://www.powershellgallery.com/packages/xWebAdministration](https://www.powershellgallery.com/packages/xWebAdministration)

This module contains resources which are responsible for managing IIS, which obviously play a key role in the front end server role of a SharePoint farm.
These resources can manage site configuring for tasks such as bindings, or remove the default IIS sites and app pools to reduce clutter.

    xWebAppPool RemoveDotNet2Pool         { Name = ".NET v2.0";            Ensure = "Absent"; }
    xWebAppPool RemoveDotNet2ClassicPool  { Name = ".NET v2.0 Classic";    Ensure = "Absent"; }
    xWebAppPool RemoveDotNet45Pool        { Name = ".NET v4.5";            Ensure = "Absent"; }
    xWebAppPool RemoveDotNet45ClassicPool { Name = ".NET v4.5 Classic";    Ensure = "Absent"; }
    xWebAppPool RemoveClassicDotNetPool   { Name = "Classic .NET AppPool"; Ensure = "Absent"; }
    xWebAppPool RemoveDefaultAppPool      { Name = "DefaultAppPool";       Ensure = "Absent"; }
    xWebSite    RemoveDefaultWebSite      { Name = "Default Web Site";     Ensure = "Absent"; PhysicalPath = "C:\inetpub\wwwroot"; }

## xCredSSP

Available at [https://www.powershellgallery.com/packages/xCredSSP](https://www.powershellgallery.com/packages/xCredSSP)

The xCredSSP module is a simple way to automate CredSSP configuration. See _[Remote sessions and the InstallAccount variable](Remote-sessions-and-the-InstallAccount-variable)_ for more information on this.

## SChannelDsc

Available at [https://www.powershellgallery.com/packages/SchannelDsc](https://www.powershellgallery.com/packages/SchannelDsc)

This module can be used to configure Secure Channel (SSL/TLS) settings in Windows, like disabling SSLv3 and enabling TLSv1.2.

## OfficeOnlineServerDsc

Available at [https://www.powershellgallery.com/packages/OfficeOnlineServerDsc](https://www.powershellgallery.com/packages/OfficeOnlineServerDsc)

This module can be used to install and manage [Office Online Server](https://docs.microsoft.com/en-us/officeonlineserver/office-online-server).

## WorkflowManagerDsc

Available at [https://www.powershellgallery.com/packages/WorkflowManagerDsc](https://www.powershellgallery.com/packages/WorkflowManagerDsc)

This module can be used to install and manage [Workflow Manager](https://docs.microsoft.com/en-us/sharepoint/governance/install-and-configure-workflow-for-sharepoint-server#install-workflow-manager).
