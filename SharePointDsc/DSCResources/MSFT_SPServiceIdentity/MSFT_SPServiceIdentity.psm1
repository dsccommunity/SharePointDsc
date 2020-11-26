function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ManagedAccount
    )

    Write-Verbose -Message "Getting identity for service instance '$Name'"

    $result = Invoke-SPDscCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        if ($params.Name -eq "SharePoint Server Search")
        {
            $processIdentity = (Get-SPEnterpriseSearchService).get_ProcessIdentity()
        }
        else
        {
            $serviceInstance = Get-SPServiceInstance -Server $env:computername | Where-Object {
                $_.TypeName -eq $params.Name
            }

            if ($null -eq $serviceInstance.service.processidentity)
            {
                Write-Verbose "WARNING: Service $($params.name) does not support setting the process identity"
            }

            $processIdentity = $serviceInstance.Service.ProcessIdentity
        }

        switch ($processIdentity.CurrentIdentityType)
        {
            "LocalSystem"
            { $ManagedAccount = "LocalSystem"
            }
            "NetworkService"
            { $ManagedAccount = "NetworkService"
            }
            "LocalService"
            { $ManagedAccount = "LocalService"
            }
            Default
            { $ManagedAccount = $processIdentity.Username
            }
        }

        return @{
            Name           = $params.Name
            ManagedAccount = $ManagedAccount
        }
    }

    return $result
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ManagedAccount
    )

    Write-Verbose -Message "Setting service instance '$Name' to '$ManagedAccount'"

    Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source) `
        -ScriptBlock {
        $params = $args[0]
        $eventSource = $args[1]

        if ($params.Name -eq "SharePoint Server Search")
        {
            $processIdentity = (Get-SPEnterpriseSearchService).get_ProcessIdentity()
        }
        else
        {
            $serviceInstance = Get-SPServiceInstance -Server $env:COMPUTERNAME | Where-Object {
                $_.TypeName -eq $params.Name
            }
            if ($null -eq $serviceInstance)
            {
                $message = "Unable to locate service $($params.Name)"
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $eventSource
                throw $message
            }

            if ($null -eq $serviceInstance.service.processidentity)
            {
                $message = "Service $($params.name) does not support setting the process identity"
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $eventSource
                throw $message
            }

            $processIdentity = $serviceInstance.Service.ProcessIdentity
        }

        if ($params.ManagedAccount -eq "LocalSystem" -or `
                $params.ManagedAccount -eq "LocalService" -or `
                $params.ManagedAccount -eq "NetworkService")
        {
            $processIdentity.CurrentIdentityType = $params.ManagedAccount
        }
        else
        {
            $managedAccount = Get-SPManagedAccount -Identity $params.ManagedAccount `
                -ErrorAction SilentlyContinue
            if ($null -eq $managedAccount)
            {
                $message = "Unable to locate Managed Account $($params.ManagedAccount)"
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $eventSource
                throw $message
            }

            $processIdentity.CurrentIdentityType = [Microsoft.SharePoint.Administration.IdentityType]::SpecificUser
            $processIdentity.ManagedAccount = $managedAccount
        }

        $processIdentity.Update()
        $processIdentity.Deploy()
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ManagedAccount
    )

    Write-Verbose -Message "Testing service instance '$Name' Process Identity"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    $result = ($CurrentValues.ManagedAccount -eq $ManagedAccount)

    if ($result -eq $false)
    {
        $message = ("Specfied ManagedAccount {$($CurrentValues.ManagedAccount)} is not in the " + `
                "desired state {$ManagedAccount}.")
        Write-Verbose -Message $message
        Add-SPDscEvent -Message $message -EntryType 'Error' -EventID 1 -Source $MyInvocation.MyCommand.Source
    }

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}
