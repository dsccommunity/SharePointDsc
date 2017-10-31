<#
.EXAMPLE
    This example shows how to modify the Managed Metadata service proxy language settings.
#>

Configuration Example 
{
    param(
        [Parameter(Mandatory = $true)]
        [PSCredential]
        $SetupAccount
    )
    Import-DscResource -ModuleName SharePointDsc

    node localhost {
        SPManagedMetadataServiceLanguageSettings ManagedMetadataServiceLanguageSettings {  
            ProxyName            = "Managed Metadata Service Application Proxy"
            DefaultLanguage      = 1033
            Languages            = @(1031, 1033)
            PsDscRunAsCredential = $SetupAccount
        }
    }
}
