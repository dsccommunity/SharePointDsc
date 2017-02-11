function Get-SPDSCWebAppExtension
{
    [CmdletBinding()]
   param(
       [Parameter(Mandatory = $true)]
       $WebApplication,

       [parameter(Mandatory = $true)]
       [ValidateSet("Default","Intranet","Internet","Extranet","Custom")]
       [System.String] 
       $Zone
   )    
   Write-Verbose "Getting Zone $Zone Settings"
   $ZoneSettings = ($WebApplication.IisSettings[[Microsoft.SharePoint.Administration.SPUrlZone]::($zone)])

   return $ZoneSettings
}