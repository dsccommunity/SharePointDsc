# Introduction

SharePointDSC is an add-on to PowerShell Desired State Configuration (DSC).
The high level concept is that you can take a specific piece of configuration and deploy how this should act as code.

You can then take the generated configuration file (.MOF) and Target this configuration to an environment / single server(node).

This is useful in various scenarios, but can become complex depending how broad the scope is of the configuration and sub components and when aligning this with best practices for SharePoint or specific SharePoint Operating procedures i.e. Extending a Web Application instead of renaming.

## Scenarios

|Scenario|Description|Complexity| Estimated Effort|
| ----------- | ----------- |----------- |----------- |
|Deploying a new  SharePoint Version| Creating an environment from scratch or using an example template for 2016 / 2019 / Subscription Edition for automation and guaranteed  repeatability.|Medium|8-16 Hrs|
|Extracting an old farms Configuration|Taking a backup / extract of the entire configuration or piece/s of configuration.Has many additional use cases once extracted.|Low|2 Hrs|
|Comparison of configuration|Comparing the configuration between a last update , change or between environment i.e. Dev / Prod|High| 6 Hrs
|Restoring configuration from Prod-->Dev|This depends on the scope of configuration(More Scope = More Lines of PowerShell) and the  intended action i.e. Change / Update / Add / Remove and aligning to Best Practices|Extremely High| Unknown|

It's entirely possible that DSC is the right fit for you , and that there is a learning / discipline requirement. Or a Gap in your knowledge/ experience this Getting Started section is designed to help you.

More information on PowerShell Desired State Configuration in general, can be found [here](https://docs.microsoft.com/en-us/powershell/scripting/dsc/overview/overview).
