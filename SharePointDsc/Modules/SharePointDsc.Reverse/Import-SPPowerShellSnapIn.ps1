# Only load snapin if using SharePoint 2013, 2016 or 2019
if (-not (Get-PSSnapin Microsoft.SharePoint.Powershell -ErrorAction SilentlyContinue))
{
    Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
}
