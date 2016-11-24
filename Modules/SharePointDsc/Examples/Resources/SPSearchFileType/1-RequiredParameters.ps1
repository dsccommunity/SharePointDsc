<#
.EXAMPLE
    This example shows how to apply settings to a sepcific URL in search
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
            SPSearchFileType PDF
            {
                FileType = "pdf"
                ServiceAppName = "Search Service Application"
                Description = "PDF Document"
                Ensure = "Present"
                PsDscRunAsCredential = $SetupAccount
            }
        }
    }
