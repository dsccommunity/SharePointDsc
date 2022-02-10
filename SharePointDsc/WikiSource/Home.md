# Welcome to the SharePointDsc wiki

SharePointDsc v#.#.#

Here you will find all the information you need to make use of the SharePoint DSC resources, including details of the resources that are available, current capabilities and known issues, and information to help plan a DSC based implementation of SharePoint.

Please leave comments, feature requests, and bug reports in the [issues section](https://github.com/dsccommunity/SharePointDsc/issues) for this module.

## Quick start

To get started, download SharePointDsc from the [PowerShell Gallery](http://www.powershellgallery.com/packages/SharePointDsc/) and then unzip it to one of your PowerShell modules folders (such as $env:ProgramFiles\WindowsPowerShell\Modules).
To install from the PowerShell gallery using PowerShellGet (in PowerShell 5.0), run the following command:

    Find-Module -Name SharePointDsc -Repository PSGallery | Install-Module

To confirm installation, run the below command and ensure you see the SharePoint DSC resources available:

    Get-DscResource -Module SharePointDsc

To view a more detailed explanation, view our _[Getting Started](Getting-Started)_ page.


## Supported SharePoint versions

SharePointDsc currently supports:

- SharePoint Server 2013 with Service Pack 1 (or a higher update level) installed, running on Windows Server 2008 R2, Windows Server 2012 or Windows Server 2012 R2.
- SharePoint Server 2016 RTM (or higher) running on either Windows Server 2012 R2 or Windows Server 2019.
- SharePoint Server 2019 RTM (or higher) running on either Windows Server 2016 or Windows Server 2019.
- SharePoint Server Subscription Edition RTM (or higher) running on either Windows Server 2019 or Windows Server 2022.

 > For SharePoint 2013 to ensure correct provisioning of the User Profile Service and the User Profile Sync Service, the [February 2015 Cumulative Update](https://support.microsoft.com/en-us/kb/2920804) is also required. If you are installing SharePoint via the DSC resources, you can [slipstream it in to the update directory](http://www.toddklindt.com/blog/Lists/Posts/Post.aspx?ID=403) so it is applied during the initial installation.

> SharePoint Foundation is not supported.

## Known Issues
There are some known issues (and their solutions/workarounds) with SharePointDsc or PowerShell:

_[Error Exceeded the configured MaxEnvelopeSize quota](Error-Exceeded-the-configured-MaxEnvelopeSize-quota)_

_[Setting up Central Administration on HTTPS](Setting-up-Central-Administration-on-HTTPS)_

_[Using CredSSP on a domain controller / single server farm](Using-CredSSP-on-a-Domain-Controller)_

## Multilingual support

Where possible, resources in SharePointDsc have been written in a way that they should support working with multiple language packs for multilingual deployments. However due to constraints in how we set up and install the product, only English ISOs are supported for installing SharePoint.

## Resource Structure

Resources inside the SharePointDSC module are categorized into 4 main groups.

- Common Resources
- Specific Resources
- Distributed Resources
- Utility Resources

To understand how to use these resources in your Configuration to avoid Syntax and undesired results go to our _[Understanding Resources](Understanding-Resources)_ section.
