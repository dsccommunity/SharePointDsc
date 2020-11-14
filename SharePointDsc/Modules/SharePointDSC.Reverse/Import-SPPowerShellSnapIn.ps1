$CurrentLocation = Get-Location
if (!(Get-PSSnapin Microsoft.SharePoint.Powershell -ErrorAction SilentlyContinue))
{
    Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction 0
}
Set-Location $CurrentLocation
