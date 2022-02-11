Setting up Central Administration on HTTPS is still not a straight forward process. Here, we describe one way to accomplish this using DSC with a choice of a couple of workarounds to ensure it stays configured properly. Starting in SharePoint 2016, the PowerShell cmdlet New-SPCentralAdministration added support for a -SecureSocketsLayer argument to initialize CA with HTTPS. This cmdlet still does not, however, support specifying a hostname to use with SNI to avoid conflicts with creating web applications on the same IP/port in IIS. So we're going to use DSC to create our farm with CA on HTTP using a high port like 9999 and then later (after creating our web apps) update the IIS binding to HTTPS with a hostname using SNI and update the AAM in SharePoint.

For the code, please see the [SharePoint.SSL.ps1](https://github.com/PowerShell/SharePointDsc/blob/dev/Modules/SharePointDsc/Examples/Small-Farm/SharePoint.SSL.ps1) example in the Examples/Small Farm folder.

## Workarounds

When running the SharePoint Products Configuration Wizard (psconfigUI.exe) on the Central Administration server, it will try to reconfigure the Central Administration web application as part of the process. In most cases, it will not recognize the hostname as part of the binding and may reset the IIS HTTPS binding and add an HTTP binding and corresponding Alternate Access Mapping (AAM).

To avoid this problem, you can use psconfig.exe from the SharePoint Management Shell instead:

```
PSConfig.exe -cmd upgrade -inplace b2b -wait -cmd applicationcontent -install -cmd installfeatures -cmd secureresources -cmd services -install
```

An alternative workaround involves removing and recreating the Central Administration web application after the farm has been provisioned. Use the following PowerShell commands in an elevated SharePoint Management Shell:

```powershell
Remove-SPWebApplication -Identity https://admin.contoso.com -Zone Default -DeleteIISSite

New-SPWebApplicationExtension -Identity https://admin.contoso.com -Name "SharePoint Central Administration v4" -Zone Default -HostHeader admin.contoso.com -Port 443 -SecureSocketsLayer
```

This method stores the IIS binding information in SharePoint so that the configuration wizard will not wipe out the existing IIS bindings when running psconfigUI.exe.

