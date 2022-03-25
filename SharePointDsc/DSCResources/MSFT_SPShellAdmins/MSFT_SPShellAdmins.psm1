function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [String]
        $IsSingleInstance,

        [Parameter()]
        [System.String[]]
        $Members,

        [Parameter()]
        [System.String[]]
        $MembersToInclude,

        [Parameter()]
        [System.String[]]
        $MembersToExclude,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $Databases,

        [Parameter()]
        [System.Boolean]
        $AllDatabases,

        [Parameter()]
        [System.String[]]
        $ExcludeDatabases
    )

    Write-Verbose -Message "Getting Shell Admins config"

    $nullreturn = @{
        IsSingleInstance = "Yes"
        Members          = $null
        MembersToInclude = $null
        MembersToExclude = $null
    }

    if ($Members -and (($MembersToInclude) -or ($MembersToExclude)))
    {
        Write-Verbose -Message ("Cannot use the Members parameter together with the " + `
                "MembersToInclude or MembersToExclude parameters")
        return $nullreturn
    }

    if ($Databases)
    {
        foreach ($database in $Databases)
        {
            if ($database.Members -and (($database.MembersToInclude) `
                        -or ($database.MembersToExclude)))
            {
                Write-Verbose -Message ("Databases: Cannot use the Members parameter " + `
                        "together with the MembersToInclude or " + `
                        "MembersToExclude parameters")
                return $nullreturn
            }

            if (!$database.Members `
                    -and !$database.MembersToInclude `
                    -and !$database.MembersToExclude)
            {
                Write-Verbose -Message ("Databases: At least one of the following " + `
                        "parameters must be specified: Members, " + `
                        "MembersToInclude, MembersToExclude")
                return $nullreturn
            }
        }
    }
    else
    {
        if (!$Members -and !$MembersToInclude -and !$MembersToExclude)
        {
            Write-Verbose -Message ("At least one of the following parameters must be " + `
                    "specified: Members, MembersToInclude, MembersToExclude")
            return $nullreturn
        }
    }

    if ($Databases -and $AllDatabases)
    {
        Write-Verbose -Message ("Cannot use the Databases parameter together with the " + `
                "AllDatabases parameter")
        return $nullreturn
    }

    if ($Databases -and $ExcludeDatabases)
    {
        Write-Verbose -Message ("Cannot use the Databases parameter together with the " + `
                "ExcludeDatabases parameter")
        return $nullreturn
    }

    $result = Invoke-SPDscCommand -Arguments @($PSBoundParameters, $PSScriptRoot) `
        -ScriptBlock {
        $params = $args[0]
        $scriptRoot = $args[1]

        Import-Module -Name (Join-Path -Path $scriptRoot -ChildPath "MSFT_SPShellAdmins.psm1")

        try
        {
            $null = Get-SPFarm -Verbose:$false
        }
        catch
        {
            Write-Verbose -Message ("No local SharePoint farm was detected. Shell admin " + `
                    "settings will not be applied")
            return $nullreturn
        }

        $shellAdmins = Get-SPShellAdmin -Verbose:$false

        $cdbPermissions = @()
        $databases = Get-SPDatabase -Verbose:$false
        if ($params.ContainsKey("ExcludeDatabases"))
        {
            $databases = $databases | Where-Object -FilterScript {
                $_.Name -notin $params.ExcludeDatabases
            }
        }

        foreach ($database in $databases)
        {
            $dbShellAdmins = Get-SPShellAdmin -Database $database.Id -Verbose:$false

            $cdbPermission = @{
                Name    = $database.Name
                Members = $dbShellAdmins.UserName
            }

            $cdbPermissions += $cdbPermission
        }

        return @{
            IsSingleInstance = "Yes"
            Members          = [System.Array]$shellAdmins.UserName
            MembersToInclude = $params.MembersToInclude
            MembersToExclude = $params.MembersToExclude
            Databases        = $cdbPermissions
            AllDatabases     = $params.AllDatabases
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
        [ValidateSet('Yes')]
        [String]
        $IsSingleInstance,

        [Parameter()]
        [System.String[]]
        $Members,

        [Parameter()]
        [System.String[]]
        $MembersToInclude,

        [Parameter()]
        [System.String[]]
        $MembersToExclude,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $Databases,

        [Parameter()]
        [System.Boolean]
        $AllDatabases,

        [Parameter()]
        [System.String[]]
        $ExcludeDatabases
    )

    Write-Verbose -Message "Setting Shell Admin config"

    if ($Members -and (($MembersToInclude) -or ($MembersToExclude)))
    {
        $message = ("Cannot use the Members parameter together with the " + `
                "MembersToInclude or MembersToExclude parameters")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    if ($Databases)
    {
        foreach ($database in $Databases)
        {
            if ($database.Members -and (($database.MembersToInclude) `
                        -or ($database.MembersToExclude)))
            {
                $message = ("Databases: Cannot use the Members parameter " + `
                        "together with the MembersToInclude or " + `
                        "MembersToExclude parameters")
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $MyInvocation.MyCommand.Source
                throw $message
            }

            if (!$database.Members `
                    -and !$database.MembersToInclude `
                    -and !$database.MembersToExclude)
            {
                $message = ("Databases: At least one of the following " + `
                        "parameters must be specified: Members, " + `
                        "MembersToInclude, MembersToExclude")
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $MyInvocation.MyCommand.Source
                throw $message
            }
        }
    }
    else
    {
        if (!$Members -and !$MembersToInclude -and !$MembersToExclude)
        {
            $message = ("At least one of the following parameters must be " + `
                    "specified: Members, MembersToInclude, MembersToExclude")
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $MyInvocation.MyCommand.Source
            throw $message
        }
    }

    if ($Databases -and $AllDatabases)
    {
        $message = ("Cannot use the Databases parameter together with the " + `
                "AllDatabases parameter")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    if ($Databases -and $ExcludeDatabases)
    {
        $message = ("Cannot use the Databases parameter together with the " + `
                "ExcludeDatabases parameter")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    $null = Invoke-SPDscCommand -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source, $PSScriptRoot) `
        -ScriptBlock {
        $params = $args[0]
        $eventSource = $args[1]
        $scriptRoot = $args[2]

        Import-Module -Name (Join-Path -Path $scriptRoot -ChildPath "MSFT_SPShellAdmins.psm1")

        try
        {
            $null = Get-SPFarm -Verbose:$false
        }
        catch
        {
            $message = ("No local SharePoint farm was detected. Shell admin " + `
                    "settings will not be applied")
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $eventSource
            throw $message
        }

        $shellAdmins = Get-SPShellAdmin -Verbose:$false

        if ($params.Members)
        {
            Write-Verbose -Message "Processing Members"
            if ($shellAdmins)
            {
                $differences = Compare-Object -ReferenceObject $shellAdmins.UserName `
                    -DifferenceObject $params.Members

                if ($null -eq $differences)
                {
                    Write-Verbose -Message ("Shell Admins group matches. No further " + `
                            "processing required")
                }
                else
                {
                    Write-Verbose -Message ("Shell Admins group does not match. Perform " + `
                            "corrective action")

                    foreach ($difference in $differences)
                    {
                        if ($difference.SideIndicator -eq "=>")
                        {
                            $user = $difference.InputObject
                            try
                            {
                                Write-Verbose -Message "Adding $member"
                                Add-SPShellAdmin -UserName $user -Verbose:$false
                            }
                            catch
                            {
                                $message = ("Error while setting the Shell Admin. The Shell " + `
                                        "Admin permissions will not be applied. Error " + `
                                        "details: $($_.Exception.Message)")
                                Add-SPDscEvent -Message $message `
                                    -EntryType 'Error' `
                                    -EventID 100 `
                                    -Source $eventSource
                                throw $message
                            }
                        }
                        elseif ($difference.SideIndicator -eq "<=")
                        {
                            $user = $difference.InputObject
                            try
                            {
                                Write-Verbose -Message "Removing $member"
                                Remove-SPShellAdmin -UserName $user -Confirm:$false -Verbose:$false
                            }
                            catch
                            {
                                $message = ("Error while removing the Shell Admin. The Shell Admin " + `
                                        "permissions will not be revoked. Error details: " + `
                                        "$($_.Exception.Message)")
                                Add-SPDscEvent -Message $message `
                                    -EntryType 'Error' `
                                    -EventID 100 `
                                    -Source $eventSource
                                throw $message
                            }
                        }
                    }
                }
            }
            else
            {
                foreach ($member in $params.Members)
                {
                    try
                    {
                        Write-Verbose -Message "Adding $member"
                        Add-SPShellAdmin -UserName $member -Verbose:$false
                    }
                    catch
                    {
                        $message = ("Error while setting the Shell Admin. The Shell Admin " + `
                                "permissions will not be applied. Error details: " + `
                                "$($_.Exception.Message)")
                        Add-SPDscEvent -Message $message `
                            -EntryType 'Error' `
                            -EventID 100 `
                            -Source $eventSource
                        throw $message
                    }
                }
            }
        }

        if ($params.MembersToInclude)
        {
            Write-Verbose -Message "Processing MembersToInclude"
            if ($shellAdmins)
            {
                foreach ($member in $params.MembersToInclude)
                {
                    if (-not $shellAdmins.UserName.Contains($member))
                    {
                        try
                        {
                            Write-Verbose -Message "Adding $member"
                            Add-SPShellAdmin -UserName $member -Verbose:$false
                        }
                        catch
                        {
                            $message = ("Error while setting the Shell Admin. The Shell Admin " + `
                                    "permissions will not be applied. Error details: " + `
                                    "$($_.Exception.Message)")
                            Add-SPDscEvent -Message $message `
                                -EntryType 'Error' `
                                -EventID 100 `
                                -Source $eventSource
                            throw $message
                        }
                    }
                }
            }
            else
            {
                foreach ($member in $params.MembersToInclude)
                {
                    try
                    {
                        Write-Verbose -Message "Adding $member"
                        Add-SPShellAdmin -UserName $member -Verbose:$false
                    }
                    catch
                    {
                        $message = ("Error while setting the Shell Admin. The Shell Admin " + `
                                "permissions will not be applied. Error details: $($_.Exception.Message)")
                        Add-SPDscEvent -Message $message `
                            -EntryType 'Error' `
                            -EventID 100 `
                            -Source $eventSource
                        throw $message
                    }
                }
            }
        }

        if ($params.MembersToExclude)
        {
            Write-Verbose -Message "Processing MembersToExclude"
            if ($shellAdmins)
            {
                foreach ($member in $params.MembersToExclude)
                {
                    if ($shellAdmins.UserName.Contains($member))
                    {
                        try
                        {
                            Write-Verbose -Message "Removing $member"
                            Remove-SPShellAdmin -UserName $member -Confirm:$false -Verbose:$false
                        }
                        catch
                        {
                            $message = ("Error while removing the Shell Admin. The Shell Admin " + `
                                    "permissions will not be revoked. Error details: " + `
                                    "$($_.Exception.Message)")
                            Add-SPDscEvent -Message $message `
                                -EntryType 'Error' `
                                -EventID 100 `
                                -Source $eventSource
                            throw $message
                        }
                    }
                }
            }
        }

        if ($params.Databases)
        {
            Write-Verbose -Message "Processing Databases parameter"
            # The Databases parameter is set
            # Compare the configuration against the actual set and correct any issues

            foreach ($database in $params.Databases)
            {
                # Check if configured database exists, throw error if not
                Write-Verbose -Message "Processing Database: $($database.Name)"

                $currentCDB = Get-SPDatabase  -Verbose:$false | Where-Object -FilterScript {
                    $_.Name -eq $database.Name
                }
                if ($null -ne $currentCDB)
                {
                    $dbShellAdmins = Get-SPShellAdmin -Database $currentCDB.Id -Verbose:$false

                    if ($database.Members)
                    {
                        Write-Verbose -Message "Processing Members"
                        if ($dbShellAdmins)
                        {
                            $differences = Compare-Object -ReferenceObject $database.Members `
                                -DifferenceObject $dbShellAdmins.UserName
                            foreach ($difference in $differences)
                            {
                                if ($difference.SideIndicator -eq "<=")
                                {
                                    $user = $difference.InputObject
                                    try
                                    {
                                        Write-Verbose -Message "Adding $user"
                                        Add-SPShellAdmin -Database $currentCDB.Id `
                                            -UserName $user `
                                            -Verbose:$false
                                    }
                                    catch
                                    {
                                        $message = ("Error while setting the Shell Admin. The " + `
                                                "Shell Admin permissions will not be applied. " + `
                                                "Error details: $($_.Exception.Message)")
                                        Add-SPDscEvent -Message $message `
                                            -EntryType 'Error' `
                                            -EventID 100 `
                                            -Source $eventSource
                                        throw $message
                                    }
                                }
                                elseif ($difference.SideIndicator -eq "=>")
                                {
                                    $user = $difference.InputObject
                                    try
                                    {
                                        Write-Verbose -Message "Removing $user"
                                        Remove-SPShellAdmin -Database $currentCDB.Id `
                                            -UserName $user `
                                            -Confirm:$false `
                                            -Verbose:$false
                                    }
                                    catch
                                    {
                                        $message = ("Error while removing the Shell Admin. The " + `
                                                "Shell Admin permissions will not be revoked. " + `
                                                "Error details: $($_.Exception.Message)")
                                        Add-SPDscEvent -Message $message `
                                            -EntryType 'Error' `
                                            -EventID 100 `
                                            -Source $eventSource
                                        throw $message
                                    }
                                }
                            }
                        }
                        else
                        {
                            foreach ($member in $database.Members)
                            {
                                try
                                {
                                    Write-Verbose -Message "Adding $member"
                                    Add-SPShellAdmin -Database $currentCDB.Id `
                                        -UserName $member `
                                        -Verbose:$false
                                }
                                catch
                                {
                                    $message = ("Error while setting the Shell Admin. The Shell " + `
                                            "Admin permissions will not be applied. Error " + `
                                            "details: $($_.Exception.Message)")
                                    Add-SPDscEvent -Message $message `
                                        -EntryType 'Error' `
                                        -EventID 100 `
                                        -Source $eventSource
                                    throw $message
                                }
                            }
                        }
                    }

                    if ($database.MembersToInclude)
                    {
                        Write-Verbose -Message "Processing MembersToInclude"
                        if ($dbShellAdmins)
                        {
                            foreach ($member in $database.MembersToInclude)
                            {
                                if (-not $dbShellAdmins.UserName.Contains($member))
                                {
                                    try
                                    {
                                        Write-Verbose -Message "Adding $member"
                                        Add-SPShellAdmin -Database $currentCDB.Id `
                                            -UserName $member `
                                            -Verbose:$false
                                    }
                                    catch
                                    {
                                        $message = ("Error while setting the Shell Admin. The " + `
                                                "Shell Admin permissions will not be applied. " + `
                                                "Error details: $($_.Exception.Message)")
                                        Add-SPDscEvent -Message $message `
                                            -EntryType 'Error' `
                                            -EventID 100 `
                                            -Source $eventSource
                                        throw $message
                                    }
                                }
                            }
                        }
                        else
                        {
                            foreach ($member in $database.MembersToInclude)
                            {
                                try
                                {
                                    Write-Verbose -Message "Adding $member"
                                    Add-SPShellAdmin -Database $currentCDB.Id `
                                        -UserName $member `
                                        -Verbose:$false
                                }
                                catch
                                {
                                    $message = ("Error while setting the Shell Admin. The Shell " + `
                                            "Admin permissions will not be applied. Error " + `
                                            "details: $($_.Exception.Message)")
                                    Add-SPDscEvent -Message $message `
                                        -EntryType 'Error' `
                                        -EventID 100 `
                                        -Source $eventSource
                                    throw $message
                                }
                            }
                        }
                    }

                    if ($database.MembersToExclude)
                    {
                        Write-Verbose -Message "Processing MembersToExclude"
                        if ($dbShellAdmins)
                        {
                            foreach ($member in $database.MembersToExclude)
                            {
                                if ($dbShellAdmins.UserName.Contains($member))
                                {
                                    try
                                    {
                                        Write-Verbose -Message "Removing $member"
                                        Remove-SPShellAdmin -Database $currentCDB.Id `
                                            -UserName $member `
                                            -Confirm:$false `
                                            -Verbose:$false
                                    }
                                    catch
                                    {
                                        $message = ("Error while removing the Shell Admin. The " + `
                                                "Shell Admin permissions will not be revoked. " + `
                                                "Error details: $($_.Exception.Message)")
                                        Add-SPDscEvent -Message $message `
                                            -EntryType 'Error' `
                                            -EventID 100 `
                                            -Source $eventSource
                                        throw $message
                                    }
                                }
                            }
                        }
                    }
                }
                else
                {
                    $message = "Specified database does not exist: $($database.Name)"
                    Add-SPDscEvent -Message $message `
                        -EntryType 'Error' `
                        -EventID 100 `
                        -Source $eventSource
                    throw $message
                }
            }
        }

        if ($params.AllDatabases)
        {
            Write-Verbose -Message "Processing AllDatabases parameter"

            $databases = Get-SPDatabase -Verbose:$false
            if ($params.ContainsKey("ExcludeDatabases"))
            {
                $databases = $databases | Where-Object -FilterScript {
                    $_.Name -notin $params.ExcludeDatabases
                }
            }
            foreach ($database in $databases)
            {
                Write-Verbose -Message "Processing Database: $($database.Name)"
                $dbShellAdmins = Get-SPShellAdmin -Database $database.Id -Verbose:$false
                if ($params.Members)
                {
                    if ($dbShellAdmins)
                    {
                        $differences = Compare-Object -ReferenceObject $dbShellAdmins.UserName `
                            -DifferenceObject $params.Members

                        if ($null -eq $differences)
                        {
                            Write-Verbose -Message ("Shell Admins group matches. No further " + `
                                    "processing required")
                        }
                        else
                        {
                            Write-Verbose -Message ("Shell Admins group does not match. Perform " + `
                                    "corrective action")

                            foreach ($difference in $differences)
                            {
                                if ($difference.SideIndicator -eq "=>")
                                {
                                    $user = $difference.InputObject
                                    try
                                    {
                                        Write-Verbose -Message "Adding $user"
                                        Add-SPShellAdmin -Database $database.Id `
                                            -UserName $user `
                                            -Verbose:$false
                                    }
                                    catch
                                    {
                                        $message = ("Error while setting the Shell Admin. The " + `
                                                "Shell Admin permissions will not be applied. " + `
                                                "Error details: $($_.Exception.Message)")
                                        Add-SPDscEvent -Message $message `
                                            -EntryType 'Error' `
                                            -EventID 100 `
                                            -Source $eventSource
                                        throw $message
                                    }
                                }
                                elseif ($difference.SideIndicator -eq "<=")
                                {
                                    $user = $difference.InputObject
                                    try
                                    {
                                        Write-Verbose -Message "Removing $user"
                                        Remove-SPShellAdmin -Database $database.Id `
                                            -UserName $user `
                                            -Confirm:$false `
                                            -Verbose:$false
                                    }
                                    catch
                                    {
                                        $message = ("Error while removing the Shell Admin. The " + `
                                                "Shell Admin permissions will not be revoked. " + `
                                                "Error details: $($_.Exception.Message)")
                                        Add-SPDscEvent -Message $message `
                                            -EntryType 'Error' `
                                            -EventID 100 `
                                            -Source $eventSource
                                        throw $message
                                    }
                                }
                            }
                        }
                    }
                    else
                    {
                        foreach ($member in $params.Members)
                        {
                            try
                            {
                                Write-Verbose -Message "Adding $member"
                                Add-SPShellAdmin -Database $database.Id `
                                    -UserName $member `
                                    -Verbose:$false
                            }
                            catch
                            {
                                $message = ("Error while setting the Shell Admin. The Shell Admin " + `
                                        "permissions will not be applied. Error details: " + `
                                        "$($_.Exception.Message)")
                                Add-SPDscEvent -Message $message `
                                    -EntryType 'Error' `
                                    -EventID 100 `
                                    -Source $eventSource
                                throw $message
                            }
                        }
                    }
                }

                if ($params.MembersToInclude)
                {
                    if ($dbShellAdmins)
                    {
                        foreach ($member in $params.MembersToInclude)
                        {
                            if (-not $dbShellAdmins.UserName.Contains($member))
                            {
                                try
                                {
                                    Write-Verbose -Message "Adding $member"
                                    Add-SPShellAdmin -Database $database.Id `
                                        -UserName $member `
                                        -Verbose:$false
                                }
                                catch
                                {
                                    $message = ("Error while setting the Shell Admin. The Shell " + `
                                            "Admin permissions will not be applied. Error " + `
                                            "details: $($_.Exception.Message)")
                                    Add-SPDscEvent -Message $message `
                                        -EntryType 'Error' `
                                        -EventID 100 `
                                        -Source $eventSource
                                    throw $message
                                }
                            }
                        }
                    }
                    else
                    {
                        foreach ($member in $params.MembersToInclude)
                        {
                            try
                            {
                                Write-Verbose -Message "Adding $member"
                                Add-SPShellAdmin -Database $database.Id `
                                    -UserName $member `
                                    -Verbose:$false
                            }
                            catch
                            {
                                $message = ("Error while setting the Shell Admin. The Shell Admin " + `
                                        "permissions will not be applied. Error details: " + `
                                        "$($_.Exception.Message)")
                                Add-SPDscEvent -Message $message `
                                    -EntryType 'Error' `
                                    -EventID 100 `
                                    -Source $eventSource
                                throw $message
                            }
                        }

                    }
                }

                if ($params.MembersToExclude)
                {
                    if ($dbShellAdmins)
                    {
                        foreach ($member in $params.MembersToExclude)
                        {
                            if ($dbShellAdmins.UserName.Contains($member))
                            {
                                try
                                {
                                    Write-Verbose -Message "Removing $member"
                                    Remove-SPShellAdmin -Database $database.Id `
                                        -UserName $member `
                                        -Confirm:$false `
                                        -Verbose:$false
                                }
                                catch
                                {
                                    $message = ("Error while removing the Shell Admin. The Shell " + `
                                            "Admin permissions will not be revoked. Error " + `
                                            "details: $($_.Exception.Message)")
                                    Add-SPDscEvent -Message $message `
                                        -EntryType 'Error' `
                                        -EventID 100 `
                                        -Source $eventSource
                                    throw $message
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [String]
        $IsSingleInstance,

        [Parameter()]
        [System.String[]]
        $Members,

        [Parameter()]
        [System.String[]]
        $MembersToInclude,

        [Parameter()]
        [System.String[]]
        $MembersToExclude,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $Databases,

        [Parameter()]
        [System.Boolean]
        $AllDatabases,

        [Parameter()]
        [System.String[]]
        $ExcludeDatabases
    )

    Write-Verbose -Message "Testing Shell Admin settings"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    if ($null -eq $CurrentValues.Members -and `
            $null -eq $CurrentValues.MembersToInclude -and `
            $null -eq $CurrentValues.MembersToExclude)
    {
        $message = "Members, MembersToInclude or MembersToExclude not specified."
        Write-Verbose -Message $message
        Add-SPDscEvent -Message $message -EntryType 'Error' -EventID 1 -Source $MyInvocation.MyCommand.Source

        Write-Verbose -Message "Test-TargetResource returned false"
        return $false
    }

    if ($Members)
    {
        Write-Verbose -Message "Processing Members parameter"
        if (-not $CurrentValues.Members)
        {
            $message = "No members currently configured."
            Write-Verbose -Message $message
            Add-SPDscEvent -Message $message -EntryType 'Error' -EventID 1 -Source $MyInvocation.MyCommand.Source

            Write-Verbose -Message "Test-TargetResource returned false"
            return $false
        }

        $differences = Compare-Object -ReferenceObject $CurrentValues.Members `
            -DifferenceObject $Members

        if ($null -eq $differences)
        {
            Write-Verbose -Message "Shell Admins group matches"
        }
        else
        {
            $message = ("Shell Admins group does not match. Actual: $($CurrentValues.Members -join ", "). " + `
                    "Desired: $($Members -join ", ")")
            Write-Verbose -Message $message
            Add-SPDscEvent -Message $message -EntryType 'Error' -EventID 1 -Source $MyInvocation.MyCommand.Source

            Write-Verbose -Message "Test-TargetResource returned false"
            return $false
        }
    }

    if ($MembersToInclude)
    {
        Write-Verbose -Message "Processing MembersToInclude parameter"
        if (-not $CurrentValues.Members)
        {
            $message = "No members currently configured."
            Write-Verbose -Message $message
            Add-SPDscEvent -Message $message -EntryType 'Error' -EventID 1 -Source $MyInvocation.MyCommand.Source

            Write-Verbose -Message "Test-TargetResource returned false"
            return $false
        }

        foreach ($member in $MembersToInclude)
        {
            if (-not($CurrentValues.Members.Contains($member)))
            {
                $message = "$member is not a Shell Admin."
                Write-Verbose -Message $message
                Add-SPDscEvent -Message $message -EntryType 'Error' -EventID 1 -Source $MyInvocation.MyCommand.Source

                Write-Verbose -Message "Test-TargetResource returned false"
                return $false
            }
            else
            {
                Write-Verbose -Message "$member is already a Shell Admin. Skipping"
            }
        }
    }

    if ($MembersToExclude)
    {
        Write-Verbose -Message "Processing MembersToExclude parameter"
        if ($CurrentValues.Members)
        {
            foreach ($member in $MembersToExclude)
            {
                if ($CurrentValues.Members.Contains($member))
                {
                    $message = "$member is a Shell Admin."
                    Write-Verbose -Message $message
                    Add-SPDscEvent -Message $message -EntryType 'Error' -EventID 1 -Source $MyInvocation.MyCommand.Source

                    Write-Verbose -Message "Test-TargetResource returned false"
                    return $false
                }
                else
                {
                    Write-Verbose -Message "$member is not a Shell Admin. Skipping"
                }
            }
        }
    }

    if ($AllDatabases)
    {
        # The AllDatabases parameter is set
        # Check the Members group against all databases
        Write-Verbose -Message "Processing AllDatabases parameter"

        foreach ($database in $CurrentValues.Databases)
        {
            # Check if configured database exists, throw error if not
            Write-Verbose -Message "Processing Database: $($database.Name)"

            if ($Members)
            {
                if (-not $database.Members)
                {
                    $message = "No members currently configured."
                    Write-Verbose -Message $message
                    Add-SPDscEvent -Message $message -EntryType 'Error' -EventID 1 -Source $MyInvocation.MyCommand.Source

                    Write-Verbose -Message "Test-TargetResource returned false"
                    return $false
                }

                $differences = Compare-Object -ReferenceObject $database.Members `
                    -DifferenceObject $Members

                if ($null -eq $differences)
                {
                    Write-Verbose -Message "Shell Admins group matches"
                }
                else
                {
                    $message = ("Shell Admins group does not match. Actual: $($database.Members -join ", "). " + `
                            "Desired: $($Members -join ", ")")
                    Write-Verbose -Message $message
                    Add-SPDscEvent -Message $message -EntryType 'Error' -EventID 1 -Source $MyInvocation.MyCommand.Source

                    Write-Verbose -Message "Test-TargetResource returned false"
                    return $false
                }
            }

            if ($MembersToInclude)
            {
                if (-not $database.Members)
                {
                    $message = "No members currently configured."
                    Write-Verbose -Message $message
                    Add-SPDscEvent -Message $message -EntryType 'Error' -EventID 1 -Source $MyInvocation.MyCommand.Source

                    Write-Verbose -Message "Test-TargetResource returned false"
                    return $false
                }

                foreach ($member in $MembersToInclude)
                {
                    if (-not($database.Members.Contains($member)))
                    {
                        $message = "$member is not a Shell Admin."
                        Write-Verbose -Message $message
                        Add-SPDscEvent -Message $message -EntryType 'Error' -EventID 1 -Source $MyInvocation.MyCommand.Source

                        Write-Verbose -Message "Test-TargetResource returned false"
                        return $false
                    }
                    else
                    {
                        Write-Verbose -Message "$member is already a Shell Admin. Skipping"
                    }
                }
            }

            if ($MembersToExclude)
            {
                if ($database.Members)
                {
                    foreach ($member in $MembersToExclude)
                    {
                        if ($database.Members.Contains($member))
                        {
                            $message = "$member is a Shell Admin."
                            Write-Verbose -Message $message
                            Add-SPDscEvent -Message $message -EntryType 'Error' -EventID 1 -Source $MyInvocation.MyCommand.Source

                            Write-Verbose -Message "Test-TargetResource returned false"
                            return $false
                        }
                        else
                        {
                            Write-Verbose -Message "$member is not a Shell Admin. Skipping"
                        }
                    }
                }
            }
        }
    }

    if ($Databases)
    {
        # The Databases parameter is set
        # Compare the configuration against the actual set
        Write-Verbose -Message "Processing Databases parameter"

        foreach ($database in $Databases)
        {
            # Check if configured database exists, throw error if not
            Write-Verbose -Message "Processing Database: $($database.Name)"

            $currentCDB = $CurrentValues.Databases | Where-Object -FilterScript {
                $_.Name -eq $database.Name
            }

            if ($null -ne $currentCDB)
            {
                if ($database.Members)
                {
                    Write-Verbose -Message "Processing Members parameter"
                    if (-not $currentCDB.Members)
                    {
                        $message = "No members currently configured."
                        Write-Verbose -Message $message
                        Add-SPDscEvent -Message $message -EntryType 'Error' -EventID 1 -Source $MyInvocation.MyCommand.Source

                        Write-Verbose -Message "Test-TargetResource returned false"
                        return $false
                    }

                    $differences = Compare-Object -ReferenceObject $currentCDB.Members `
                        -DifferenceObject $database.Members

                    if ($null -eq $differences)
                    {
                        Write-Verbose -Message "Shell Admins group matches"
                    }
                    else
                    {
                        $message = ("Shell Admins group does not match. Actual: $($currentCDB.Members -join ", "). " + `
                                "Desired: $($database.Members -join ", ")")
                        Write-Verbose -Message $message
                        Add-SPDscEvent -Message $message -EntryType 'Error' -EventID 1 -Source $MyInvocation.MyCommand.Source

                        Write-Verbose -Message "Test-TargetResource returned false"
                        return $false
                    }
                }

                if ($database.MembersToInclude)
                {
                    Write-Verbose -Message "Processing MembersToInclude parameter"
                    if (-not $currentCDB.Members)
                    {
                        $message = "No members currently configured."
                        Write-Verbose -Message $message
                        Add-SPDscEvent -Message $message -EntryType 'Error' -EventID 1 -Source $MyInvocation.MyCommand.Source

                        Write-Verbose -Message "Test-TargetResource returned false"
                        return $false
                    }

                    foreach ($member in $database.MembersToInclude)
                    {
                        if (-not($currentCDB.Members.Contains($member)))
                        {
                            $message = "$member is not a Shell Admin."
                            Write-Verbose -Message $message
                            Add-SPDscEvent -Message $message -EntryType 'Error' -EventID 1 -Source $MyInvocation.MyCommand.Source

                            Write-Verbose -Message "Test-TargetResource returned false"
                            return $false
                        }
                        else
                        {
                            Write-Verbose -Message "$member is already a Shell Admin. Skipping"
                        }
                    }
                }

                if ($database.MembersToExclude)
                {
                    Write-Verbose -Message "Processing MembersToExclude parameter"
                    if ($currentCDB.Members)
                    {
                        foreach ($member in $database.MembersToExclude)
                        {
                            if ($currentCDB.Members.Contains($member))
                            {
                                $message = "$member is a Shell Admin."
                                Write-Verbose -Message $message
                                Add-SPDscEvent -Message $message -EntryType 'Error' -EventID 1 -Source $MyInvocation.MyCommand.Source

                                Write-Verbose -Message "Test-TargetResource returned false"
                                return $false
                            }
                            else
                            {
                                Write-Verbose -Message "$member is not a Shell Admin. Skipping"
                            }
                        }
                    }
                }
            }
            else
            {
                $message = "Specified database does not exist: $($database.Name)"
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $MyInvocation.MyCommand.Source
                throw $message
            }
        }
    }

    Write-Verbose -Message "Test-TargetResource returned true"
    return $true
}

Export-ModuleMember -Function *-TargetResource
