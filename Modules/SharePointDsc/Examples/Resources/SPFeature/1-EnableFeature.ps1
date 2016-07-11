<#
.EXAMPLE
    This example shows how to enable a site collection scoped feature 
#>

    Configuration Example 
    {
        param(
            [Parameter(Mandatory = $true)]
            [PSCredential]
            $SetupAccount
        )
        Import-DscResource -ModuleName SharePointDsc

        SPFeature EnableViewFormsLockDown
        {
            Name                 = "ViewFormPagesLockDown"
            Url                  = "http://www.contoso.com"
            FeatureScope         = "Site"
            PsDscRunAsCredential = $SetupAccuount
            Version              = "1.0.0.0"     
        }
    }
