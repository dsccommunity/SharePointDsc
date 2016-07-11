<#
.EXAMPLE
    This example shows how to disable a site collection scoped feature 
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
            Ensure               = "Absent"
            PsDscRunAsCredential = $SetupAccuount
            Version              = "1.0.0.0"     
        }
    }
