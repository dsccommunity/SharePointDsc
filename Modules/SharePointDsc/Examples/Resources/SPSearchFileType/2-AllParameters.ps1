<#
.EXAMPLE
    This example shows how to set a certificate for authentication to a content source
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
                MimeType = "application/pdf"
                Enabled = $false
                Ensure = "Present"
                PsDscRunAsCredential = $SetupAccount
            }
        }
    }
