<#
.EXAMPLE
    This example shows how remove a property bag value in a site collection.
#>

Configuration Example
{
    param
    (
        [Parameter(Mandatory = $true)]
        [PSCredential]
        $SetupAccount
    )

    Import-DscResource -ModuleName SharePointDsc

    node localhost
    {
        SPSitePropertyBag Site_APPCodeProperty
        {
            PsDscRunAsCredential = $SetupAccount
            Url    = "https://web.contoso.com"
            Key    = "KeyToRemove"
            Ensure = "Absent"
        }
    }
}
