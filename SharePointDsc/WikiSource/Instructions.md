# Usage instructions for the "Flexible Farm" example

We have created an example configuration that can be used to deploy SharePoint environments in a flexible way.

The configuration is able to deploy SharePoint using Front-End, Back-End, Search Front-End and Search Back-End servers. All on one server or spread across multiple servers.

**NOTE:** This script hasn't been fully tested yet. We are in the process of doing that, but wanted to share it anyways so it can be used as an example by others.

## Scripts

Consists our of seven files:

| File name | Description | 
| --- | ---| 
| **SharePoint 2019.psd1** | PowerShell data file used as Configuration Data file for the DSC Configuration|
| **ValidateConfigFile.ps1** | Script to validate if the data file has the correct fields and data |
| **PrepVariables.ps1** | Script that loads the data file into memory, requests additional data (like passwords), so it can be used by all other files. |
| **PrepServers.ps1** | Script that prepares the target servers: Deploy DSC modules, generate DSC encryption certificate and configure LCM |
| **PrepServersConfig.ps1** | Meta DSC Configuration used to configure the LCM |
| **Deploy_SharePoint.ps1** | DSC Configuration to deploy and configure SharePoint |
| **ResetVariables.ps1** | Script to reset all password variables, so the PrepVariables script will ask for them again (for example: if you have entered an incorrect password). |

## Usage

1. Make sure you update the values in the **SharePoint 2019.psd1**
1. Run the **ValidateConfigFile.ps1** to validate that the psd1 is valid
1. Run the **PrepVariables.ps1** script, select the file **SharePoint 2019.psd1** and enter the credentials of the used accounts
1. Run **PrepServers.ps1** to configure the target servers correctly
1. Run **Deploy_SharePoint.ps1** to compile the MOF files
1. Run `Start-DscConfiguration` to deploy the MOF files

**NOTE:** If you have made a mistake entering credentials, just run the **ResetVariables.ps1** script and run the **PrepVariables.ps1** script again.

## Location

The example can be found [here](https://github.com/dsccommunity/SharePointDsc/tree/master/SharePointDsc/Examples/Flexible%20Farm).
