If you want to troubleshoot an issue, having some logging or troubleshooting
information available is very useful. Especially when you ask someone else for
assistance. That is why SharePointDsc has a cmdlet available that is able to
export several pieces of information:

- DSC Verbose logs
- SPDSC Event log
- PowerShell version
- Operating System version
- LCM configuration

## Parameters

| Parameter | Attribute | DataType | Description | Allowed Values |
| --- | --- | --- | --- | --- |
| **ExportFilePath** | Mandatory | String | Path where to export the diagnostic data to | |
| **NumberOfDays** | Optional | UInt | The number of days to export the data of (Default = 7) | |
| **Anonymize** | Optional | Switch | Specify to anonymize the exported data |  |
| **Server** | Mandatory | String | Specifies the server name to replace during anonimization  | |
| **Domain** | Mandatory | Switch | Specifies the domain name to replace during anonimization | |
| **Url** | Mandatory | Switch | Specifies the url to replace during anonimization | |

## Examples

### Example 1

Export diagnostic info to C:\Output

```PowerShell
Export-SPDscDiagnosticData -ExportFilePath 'C:\Output'
```

### Example 2

Export diagnostic info of the last 14 days to C:\Output

```PowerShell
Export-SPDscDiagnosticData -ExportFilePath 'C:\Output' -NumberOfDays 14
```

### Example 3

Export anonymized diagnostic info to C:\Output

```PowerShell
Export-SPDscDiagnosticData -ExportFilePath 'C:\Output' -Anonymize -Server 'server1' -Domain 'contoso.com' -Url 'https://sharepoint.contoso.com'
```
