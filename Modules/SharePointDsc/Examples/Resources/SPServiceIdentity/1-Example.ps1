<#
.EXAMPLE
    This example shows how to set the SandBox Code Service to run under a specifed service account. 
    The account must already be registered as a managed account.
#>

    SPServiceIdentity SandBoxUserAccount
    {  
        Name           = "Microsoft SharePoint Foundation Sandboxed Code Service"
        ManagedAccount = "CONTOSO\SPUserCode"
        InstallAccount = $InstallAccount
    }
    