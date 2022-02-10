If you are keen to make SharePointDsc better, why not consider contributing your work to the project? Every little change helps us make a better resource for everyone to use, and we would love to have contributions from the community.

# Core contribution guidelines

We follow all of the standard contribution guidelines for DSC resources [outlined in the DscResources repo](https://github.com/PowerShell/DscResources/blob/master/CONTRIBUTING.md), so please review these as a baseline for contributing. Specifically, be sure to read the following linked article from that page:

* [Style Guidelines and Best Practices](https://github.com/PowerShell/DscResources/blob/master/StyleGuidelines.md)

## SharePointDsc specific coding principles

The Get-TargetResource function should not return $null as a result. It may, however, return a hashtable where some properties have a $null value. For example:
```PowerShell
function Get-TargetResource
{
    $nullreturn = @{
      ServiceAppName = $ServiceAppName
      Name           = $Name
      RequestLimit   = $null
      WaitTime       = $null
      Ensure         = "Absent"
    }
    return $nullreturn
}
```

In some cases, SharePoint does not publically publish information via the object model. If this is the case, reflection can be used to call the internal method. Since this comes with significant risks, however, we only allow reflection to be used to retrieve data and **not** to set data.

## Design Guidelines

To help ensure that SharePointDsc resources are created in a consistent manner, there are a number of design guidelines that guide the thinking applied to how the resources should be built. These design rules should be taken into account when submitting changes or new functionality to the SharePointDsc module.

1. Each resource in SharePointDsc should strive to make changes to only the current server, and not require a remote connection to other servers to complete their work.
2. Supported versions of SharePoint for SharePointDsc are SharePoint Server 2013 with Service Pack 1 or higher, SharePoint Server 2016 and SharePoint Server 2019. SharePoint 2010 is not supported due to requiring PowerShell 4, which is not supported with that version of the product. Where a resource will not work with all versions we support (such as functionality or features being added or deprecated between versions), a clear and concise error should be returned that explains this.

3. Any breaking change should be committed to a new branch so that it can be included in the next major version release. A change will be considered a 'breaking' change under the following circumstances:

* A new mandatory property is added to a resource
* The data type of any resource property is changed
* Any property is removed or renamed in a resource
* A resource is removed
* A change in the expected outcome of how a resource behaves is made
* Any change that modifies the list of prerequisites for the module to run

4. Resources that will make changes within site collections should not be part of SharePointDsc. The reason is that these types of changes can conflict with actions performed by the site collection owners/administrators. For example: In SPSite we use the title field during site creation, but do not update the title later on. This is because a site collection administrator can have a reason for changing the title and in such a case, SharePointDsc would reset the title, confusing the site collection administrator.

  * Only in specific cases can we deviate from this principle.
  * One exception is the SPWeb resource. That was fully coded already and submitted as a Pull Request. Since we didn't want to throw away that code, we decided to include it into the module.

# SharePointDsc specific guidelines

## Dynamic documentation

With over 100 resources in our module, we want to keep the documentation work light. To aid this, we are generating our documentation dynamically. Therefore, for each DSC resource we have, the following items must be completed so we can generate these:

1. In the folder for the resource, place a readme.md file that contains heading 'Description' and a text description of the module.
2. In the schema.mof file for the resource, ensure that there are description attributes on all properties.
3. Generate 1 or more example configurations for the resource in the Examples/resources/[resource name] folder using PowerShell help syntax to describe the example at the top of the file. Each example configuration must be complete and runnable, must be called "example" and it must only take parameters of PSCredential types. This will allow our unit tests to validate the examples as part of our build process.

With these items in place, we can dynamically generate the help files for PowerShell as well as this wiki.

## Testing against SharePoint Server 2013, 2016, 2019 and Subscription Edition

SharePointDsc is designed to work correctly against the Server 2013, 2016, 2019 and Subscription Edition versions of the product. The automated unit tests that are run in SharePointDsc will execute against all versions of the product using the stub modules we include in the unit tests directory.

Where a resource applies to only a specific version (such as [SPUserProfileSyncService](https://github.com/dsccommunity/SharePointDsc/blob/master/SharePointDsc/DSCResources/MSFT_SPUserProfileSyncService/MSFT_SPUserProfileSyncService.psm1)) the code should throw meaningful errors to indicate that it should not be used with the installed version of the product.

## Test your changes on a SharePoint test environment

This might sound a little stupid, but in the past we noticed that code changes were submitted that could never work on a SharePoint environment. So always make sure you test your updates against a real life SharePoint environment! You can use [this](https://github.com/dsccommunity/SharePointDsc/wiki/Creating-an-Azure-development-environment) article to create your own test environment in Azure.

# Tools

For SharePointDsc there are several tools available to help developing or are being used in the GitHub repository.

## GitHub Desktop

In order to work with a local copy of the repository, you need the [GitHub Desktop](https://desktop.github.com/). The GitHub Desktop include the [Git tools](https://git-scm.com/downloads), but adds a nice GUI on top of it. Using this GUI you can see what commits have been made and what changes where made in those commits. Checkout the training section below if you want to learn more about Git.

## Visual Studio Code

To develop SharePointDsc, we recommend the use of [Visual Studio Code](https://code.visualstudio.com/) with the [PowerShell extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode.PowerShell) to enable PowerShell support. The SharePointDsc project already contains some definitions that configure Visual Studio Code to use the correct formatting.

## PSScriptAnalyzer
To check code for compliance to PowerShell best practices, we are using [PSScriptAnalyzer](https://github.com/PowerShell/PSScriptAnalyzer). You can install this module locally as well and have your code checked. Visual Studio Code is also using this module to display possible issues in your PowerShell code.

## Azure DevOps

We are using [Azure DevOps](https://dev.azure.com/dsccommunity/SharePointDsc/) as the Continuous Integration solution for our project. When a Pull Request is submitted, Azure DevOps will run all the required tests against all supported SharePoint versions. If you want to see what happened, for example if the test fails, you can review the Azure DevOps log by clicking on the "Details" link behind the Azure DevOps test.

Since the log is very big, a quick way to see which tests failed is to click "View raw log" link and searching for "[-]", which is present in all failed tests.

## Pester

All DSC Resource Kit modules are using [Pester](https://github.com/pester/Pester) to perform Unit tests on the code. Pester is also able to calculate the code coverage off all tests. Check out the training section below if you want to learn more about Pester.

> _**IMPORTANT**: Make sure you run the below commands:_
> * _Using Windows PowerShell v5.1. Running unit tests might work on PowerShell v7, but this hasn't been tested yet (because SharePoint itself requires Windows PowerShell v5.1). Testing running unit tests with PowerShell v7 is on the roadmap._
> * _In an elevated PowerShell session. The code will throw a lot of errors when you don't!_

You can run all tests by performing these steps:
* Open PowerShell
* Browse to the local clone folder (e.g. c:\src\SharePointDsc)
* Build the module by running `.\build.ps1 -Tasks Build`
* Start all tests by running `.\build.ps1 -Tasks Test`

This executes all tests for SharePoint 2013 on the code. This can take several hours to complete, depending on the specifications of your machine. If you want to run the tests for a different SharePoint version, use:

**SharePoint 2016**
```PowerShell
.\build.ps1 -Tasks test -PesterScript @(@{ Path = '<module_path>/Tests/Unit'; Parameters = @{SharePointCmdletModule = '<module_path>/Tests/Unit/Stubs/SharePoint/16.0.4456.1000/Microsoft.SharePoint.PowerShell.psm1' }})
```
**SharePoint 2019**
```PowerShell
 .\build.ps1 -Tasks test -PesterScript @(@{ Path = '<module_path>/Tests/Unit'; Parameters = @{SharePointCmdletModule = '<module_path>/Tests/Unit/Stubs/SharePoint/16.0.10337.12109/Microsoft.SharePoint.PowerShell.psm1' }})
```
**SharePoint Subscription Edition**
```PowerShell
 .\build.ps1 -Tasks test -PesterScript @(@{ Path = '<module_path>/Tests/Unit'; Parameters = @{SharePointCmdletModule = '<module_path>/Tests/Unit/Stubs/SharePoint/16.0.14326.20450/SharePointServer.psm1' }})
```

We are also checking for compliance to the [coding style guide and other generic tests](https://github.com/PowerShell/DscResource.Tests#dsc-resource-common-meta-tests). You can run these tests locally by executing the following steps:
* Open PowerShell
* Browse to the local clone folder
* Build the module by running (required if you restarted PowerShell or updated a resource) `.\build.ps1 -Tasks Build`
* Start all High Quality Resource Module (HQRM) tests by running `.\build.ps1 -Tasks hqrmtests`
This executes all HQRM tests on the code.

## Test single resource
To run an individual Pester test, run the following script (update the first two lines with the correct values):
```PowerShell
$modulePath = '<module_path>' # e.g. C:\src\SharePointDsc
$resource = '<resource_name>' # e.g. SPSite

cd $modulePath
.\build.ps1 -Tasks Build

$path15 = Join-Path -Path $modulePath -ChildPath '\Tests\Unit\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1'
$path16 = Join-Path -Path $modulePath -ChildPath '\Tests\Unit\Stubs\SharePoint\16.0.4456.1000\Microsoft.SharePoint.PowerShell.psm1'
$path19 = Join-Path -Path $modulePath -ChildPath '\Tests\Unit\Stubs\SharePoint\16.0.10337.12109\Microsoft.SharePoint.PowerShell.psm1'
$pathSE = Join-Path -Path $modulePath -ChildPath '\Tests\Unit\Stubs\SharePoint\16.0.14326.20450\SharePointServer.psm1'

$testPath = Join-Path -Path $modulePath -ChildPath ".\Tests\Unit\SharePointDsc\SharePointDsc.$resource.Tests.ps1"
$compiledModulePath = Split-Path -Path (Get-Module SharePointDsc).Path
$resourcePath = Join-Path -Path $compiledModulePath -ChildPath "\DSCResources\MSFT_$resource\MSFT_$resource.psm1"
Invoke-Pester -Script @(
    @{ Path = $testPath; Parameters = @{SharePointCmdletModule = $path15 } },
    @{ Path = $testPath; Parameters = @{SharePointCmdletModule = $path16 } },
    @{ Path = $testPath; Parameters = @{SharePointCmdletModule = $path19 } },
    @{ Path = $testPath; Parameters = @{SharePointCmdletModule = $pathSE } }
) -CodeCoverage $resourcePath
```
This will run the unit tests for all four SharePoint versions **and** will calculate code coverage of the unit tests across these versions.

**NOTE:** Make sure you have version 4.10.1 of Pester. Update the module from the PowerShell Gallery by running the command `Install-Module Pester -RequiredVersion 4.10.1 -Force`

**NOTE 2:** If you have Windows 10, please read [this page](https://github.com/pester/Pester/wiki/Installation-and-Update) to update successfully to the most recent version:

**NOTE 3:** When you are troubleshooting Pester tests and you make a code change in the resource, you have to build the module again. Updates to the Pester test itself do not require this.

## Reviewable

When a Pull Request is submitted, a code review will have to take place to ensure it meets all defined standards. The code review will be done via [Reviewable](https://reviewable.io), a platform that easily enables reviewers to check code changes, add comments and approve changes. Only when all review comments are resolved will we be able to merge the Pull Request.

# Troubleshooting

The Microsoft Docs site has a good [article on troubleshooting DSC](https://docs.microsoft.com/en-us/powershell/dsc/troubleshooting) which has a list of tips and tricks on how to collect information while troubleshooting DSC.

When troubleshooting an issue, you can use the [built-in debugging possibilities](https://docs.microsoft.com/en-us/powershell/dsc/debugresource) in PowerShell DSC. Running the command `Enable-DscDebug -BreakAll` on the target machine enables debugging. By running `Start-DscConfiguration` and specifying the configuration to deploy, a new deployment starts, stopping with the following information:
  ```PowerShell
Enter-PSSession -ComputerName TEST-SRV -Credential <credentials>
Enter-PSHostProcess -Id 9000 -AppDomainName DscPsPluginWkr_AppDomain
Debug-Runspace -Id 9
  ```
By running these commands, you connect to the remote machine, entering a debug session.

Another debug option is to open the Pester file and the resource psm1 file. By placing breakpoints in those files and running the Pester file, PowerShell stops at the set breakpoint. This enables you to step through the code, troubleshooting either the resource or the Pester test.

# Training

The following resources can be used to get familiar with several technologies used within SharePointDsc:

* PowerShell Desired State Configuration and SharePointDsc
  * [Microsoft Learn: "Getting Started with PowerShell Desired State Configuration"](https://docs.microsoft.com/en-us/shows/getting-started-with-powershell-dsc/)
  * [Microsoft Learn: "Advanced PowerShell Desired State Configuration"](https://docs.microsoft.com/en-us/shows/advanced-powershell-dsc-and-custom-resources/)
  * [Microsoft Learn: "SharePoint Automation with DSC"](https://docs.microsoft.com/en-us/shows/sharepoint-automation-with-dsc/)
* Git
  * [Git manual](https://git-scm.com/book/en/v2)
  * [PluralSight: "How Git Works"](https://app.pluralsight.com/library/courses/how-git-works/table-of-contents) This is a very good training to get familiar with the Git concept.
  * [PluralSight: "Mastering Git"](https://app.pluralsight.com/library/courses/mastering-git/table-of-contents) This is a very good training to get familiar with the Git concept.
* Pester
  * [Microsoft Learn: "Testing PowerShell with Pester"](https://docs.microsoft.com/en-us/shows/testing-powershell-with-pester/)
  * [PluralSight: "Testing PowerShell with Pester"](https://www.pluralsight.com/courses/powershell-testing-pester)

**NOTE:** A subscription is required for the PluralSight trainings
