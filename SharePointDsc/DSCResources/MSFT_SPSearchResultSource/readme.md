# Description

**Type:** Distributed
**Requires CredSSP:** No

This resource is used to configure search result sources in the SharePoint
search service application. Result sources can be configured to be of the
following provider types:

* Exchange Search Provider
* Local People Provider
* Local SharePoint Provider
* OpenSearch Provider
* Remote People Provider
* Remote SharePoint Provider

> **Important:**
> The above provider types are specific to the used localized version of SharePoint.
> Please make sure you use the correct localized values. Use the below script to
> check of all possible values.

The default value for the Ensure parameter is Present. When not specifying this
parameter, the result source is created.

To define a result source as global, use the value 'SSA' as the ScopeName
value and 'Global' as the ScopeUrl value (the parameter needs to have a value).

## Script

``` PowerShell
$serviceApp = Get-SPEnterpriseSearchServiceApplication -Identity "SearchServiceAppName"

$fedManager = New-Object Microsoft.Office.Server.Search.Administration.Query.FederationManager($serviceApp)
$providers = $fedManager.ListProviders()
$providers.Keys
```
