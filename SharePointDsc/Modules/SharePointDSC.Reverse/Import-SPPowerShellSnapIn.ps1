$location = Join-Path -Path $(Get-Location) -ChildPath ".."
if (!(Get-PSSnapin Microsoft.SharePoint.Powershell -ErrorAction SilentlyContinue))
{
    Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction 0
}
Set-Location $location
