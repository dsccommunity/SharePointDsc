Configuration Deploy_PrepServers
{
    param
    (
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration

    node $AllNodes.NodeName
    {
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
            CertificateId      = $Node.Thumbprint.ToUpper()
        }
    }
}