# SharePointDsc

Build status: [![Build status](https://ci.appveyor.com/api/projects/status/aj6ce04iy5j4qcd4/branch/master?svg=true)](https://ci.appveyor.com/project/PowerShell/xsharepoint/branch/master)

Discuss SharePointDsc now: [![Gitter](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/PowerShell/xSharePoint?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)

The SharePointDsc PowerShell module (formerly known as xSharePoint) provides
DSC resources that can be used to deploy and manage a SharePoint farm.

Please leave comments, feature requests, and bug reports in the issues tab for
this module.

If you would like to modify SharePointDsc module, please feel free. Please
refer to the [Contribution Guidelines](https://github.com/PowerShell/SharePointDsc/wiki/Contributing%20to%20SharePointDSC)
for information about style guides, testing and patterns for contributing
to DSC resources.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/)
or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any
additional questions or comments.

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

The minimum PowerShell version required is 4.0, which ships in Windows 8.1
or Windows Server 2012R2 (or higher versions). The preferred version is
PowerShell 5.0 or higher, which ships with Windows 10 or Windows Server 2016.
This is discussed [on the SharePointDsc wiki](https://github.com/PowerShell/SharePointDsc/wiki/Remote%20sessions%20and%20the%20InstallAccount%20variable),
but generally PowerShell 5 will run the SharePoint DSC resources faster and
with improved verbose level logging.

## Documentation and examples

For a full list of resources in SharePointDsc and examples on their use, check
out the [SharePointDsc wiki](https://github.com/PowerShell/SharePointDsc/wiki).
You can also review the "examples" directory in the SharePointDSC module for
some general use scenarios for all of the resources that are in the module.

## Changelog

A full list of changes in each version can be found in the
[change log](CHANGELOG.md)

## Project Throughput

[![Throughput Graph](https://graphs.waffle.io/PowerShell/SharePointDsc/throughput.svg)](https://waffle.io/PowerShell/SharePointDsc/metrics/throughput)
