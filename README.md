# SharePointDsc

[![Build Status](https://dev.azure.com/dsccommunity/SharePointDsc/_apis/build/status/dsccommunity.SharePointDsc?branchName=master)](https://dev.azure.com/dsccommunity/SharePointDsc/_build/latest?definitionId=14&branchName=master)
![Azure DevOps coverage (branch)](https://img.shields.io/azure-devops/coverage/dsccommunity/SharePointDsc/14/master)
[![Azure DevOps tests](https://img.shields.io/azure-devops/tests/dsccommunity/SharePointDsc/14/master)](https://dsccommunity.visualstudio.com/SharePointDsc/_test/analytics?definitionId=14&contextType=build)
[![PowerShell Gallery (with prereleases)](https://img.shields.io/powershellgallery/v/SharePointDsc.svg?include_prereleases&label=SharePointDsc%20Preview)](https://www.powershellgallery.com/packages/SharePointDsc/)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/SharePointDsc.svg?&label=SharePointDsc)](https://www.powershellgallery.com/packages/SharePointDsc/)

The SharePointDsc PowerShell module (formerly known as xSharePoint) provides
DSC resources that can be used to deploy and manage a SharePoint farm.

Please leave comments, feature requests, and bug reports in the issues tab for
this module.

Information about this module, new releases and tips/tricks will be shared on the
[SharePointDsc blog](https://techcommunity.microsoft.com/t5/SharePointDsc/bg-p/SharePointDsc).

## Code of Conduct

This project has adopted this [Code of Conduct](CODE_OF_CONDUCT.md).

## Releases

For each merge to the branch `master` a preview release will be
deployed to [PowerShell Gallery](https://www.powershellgallery.com/).
Periodically a release version tag will be pushed which will deploy a
full release to [PowerShell Gallery](https://www.powershellgallery.com/).

## Contributing

If you would like to modify SharePointDsc module, please feel free. Please
refer to the [Contribution Guidelines](https://github.com/dsccommunity/SharePointDsc/wiki/Contributing%20to%20SharePointDSC)
for information about style guides, testing and patterns for contributing
to DSC resources.

Also check out common DSC Community [contributing guidelines](https://dsccommunity.org/guidelines/contributing).

## Installation

To manually install the module, download the source code and unzip the contents
of the \Modules\SharePointDsc directory to the
$env:ProgramFiles\WindowsPowerShell\Modules folder

To install from the PowerShell gallery using PowerShellGet (in PowerShell 5.0)
run the following command:

    Find-Module -Name SharePointDsc -Repository PSGallery | Install-Module

To confirm installation, run the below command and ensure you see the
SharePoint DSC resoures available:

    Get-DscResource -Module SharePointDsc

## Requirements

The minimum PowerShell version required is 5.0, available for all currently
supported operating systems. The preferred version is PowerShell 5.1, which
ships with Windows 10 or Windows Server 2016. This is discussed
[on the SharePointDsc wiki](https://github.com/dsccommunity/SharePointDsc/wiki/Remote%20sessions%20and%20the%20InstallAccount%20variable).

## Documentation and examples

For a full list of resources in SharePointDsc and examples on their use, check
out the [SharePointDsc wiki](https://github.com/dsccommunity/SharePointDsc/wiki).
You can also review the "examples" directory in the SharePointDSC module for
some general use scenarios for all of the resources that are in the module.

## Changelog

A full list of changes in each version can be found in the
[change log](CHANGELOG.md)
