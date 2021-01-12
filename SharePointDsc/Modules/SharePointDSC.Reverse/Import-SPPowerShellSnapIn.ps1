if (-not (Get-PSSnapin Microsoft.SharePoint.Powershell -ErrorAction SilentlyContinue))
{
    Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
}