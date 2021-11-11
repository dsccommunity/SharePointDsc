$stack = Get-PSCallStack

if ($stack[1].Position.Text -eq 'Export-SPConfiguration')
{
    if (-not (Get-PSSnapin Microsoft.SharePoint.Powershell -ErrorAction SilentlyContinue))
    {
        Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
    }
}
