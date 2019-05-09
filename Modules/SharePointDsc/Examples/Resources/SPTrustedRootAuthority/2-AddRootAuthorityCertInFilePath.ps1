<#
.EXAMPLE
    This example deploys a SP Trusted Root Authority to the local farm.
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
            SPTrustedRootAuthority SampleRootAuthority
            {
                Name                 = "Contoso"
                CertificateFilePath  = "C:\Certificates\RootAuthority.cer"
                Ensure               = "Present"
                PsDscRunAsCredential = $SetupAccount
            }
        }
    }
