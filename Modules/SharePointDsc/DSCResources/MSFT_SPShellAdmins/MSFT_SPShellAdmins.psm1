function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)] 
        [System.String]
        $Name,

        [parameter(Mandatory = $false)]
        [System.String[]]
        $Members,

        [parameter(Mandatory = $false)]
        [System.String[]]
        $MembersToInclude,

        [parameter(Mandatory = $false)]
        [System.String[]]
        $MembersToExclude,

        [parameter(Mandatory = $false)]
        [Microsoft.Management.Infrastructure.CimInstance[]] 
        $ContentDatabases,

        [parameter(Mandatory = $false)]
        [System.Boolean]
        $AllContentDatabases,

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Getting Shell Admins config"

    if ($Members -and (($MembersToInclude) -or ($MembersToExclude))) 
    {
        Write-Verbose -Message ("Cannot use the Members parameter together with the " + `
                                "MembersToInclude or MembersToExclude parameters")
        return $null
    }

    if ($ContentDatabases) 
    {
        foreach ($contentDatabase in $ContentDatabases) 
        {
            if ($contentDatabase.Members -and (($contentDatabase.MembersToInclude) `
                -or ($contentDatabase.MembersToExclude))) 
            {
                Write-Verbose -Message ("ContentDatabases: Cannot use the Members parameter " + `
                                        "together with the MembersToInclude or " + `
                                        "MembersToExclude parameters")
                return $null
            }

            if (!$contentDatabase.Members `
                -and !$contentDatabase.MembersToInclude `
                -and !$contentDatabase.MembersToExclude) 
            {
                Write-Verbose -Message ("ContentDatabases: At least one of the following " + `
                                        "parameters must be specified: Members, " + `
                                        "MembersToInclude, MembersToExclude")
                return $null
            }
        }
    } 
    else 
    {
        if (!$Members -and !$MembersToInclude -and !$MembersToExclude) 
        {
            Write-Verbose -Message ("At least one of the following parameters must be " + `
                                    "specified: Members, MembersToInclude, MembersToExclude")
            return $null
        }
    }

    if ($ContentDatabases -and $AllContentDatabases) 
    {
        Write-Verbose -Message ("Cannot use the ContentDatabases parameter together with the " + `
                                "AllContentDatabases parameter")
        return $null
    }

    $result = Invoke-SPDSCCommand -Credential $InstallAccount `
                                  -Arguments @($PSBoundParameters, $PSScriptRoot) `
                                  -ScriptBlock {
        $params = $args[0]
        $scriptRoot = $args[1]
        
        Import-Module -Name (Join-Path -Path $scriptRoot -ChildPath "MSFT_SPShellAdmins.psm1")
        
        try 
        {
            $spFarm = Get-SPFarm
        } 
        catch 
        {
            Write-Verbose -Message ("No local SharePoint farm was detected. Shell admin " + `
                                    "settings will not be applied")
            return $null
        }

        $shellAdmins = Get-SPShellAdmin
        $allContentDatabases = $true

        $cdbPermissions = @()
        $databases = Get-SPContentDatabase
        foreach ($contentDatabase in $databases) 
        {
            $cdbPermission = @{}
            
            $cdbPermission.Name = $contentDatabase.Name
            $dbShellAdmins = Get-SPShellAdmin -Database $contentDatabase.Id
            $cdbPermission.Members = $dbShellAdmins.UserName
            
            $cdbPermissions += $cdbPermission            
        } 

        return @{
            Name = $params.Name
            Members = $shellAdmins.UserName
            MembersToInclude = $params.MembersToInclude
            MembersToExclude = $params.MembersToExclude
            ContentDatabases = $cdbPermissions
            AllContentDatabases = $params.AllContentDatabases
            InstallAccount = $params.InstallAccount
        }
    }
    return $result
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)] 
        [System.String]
        $Name,

        [parameter(Mandatory = $false)]
        [System.String[]]
        $Members,

        [parameter(Mandatory = $false)]
        [System.String[]]
        $MembersToInclude,

        [parameter(Mandatory = $false)]
        [System.String[]]
        $MembersToExclude,

        [parameter(Mandatory = $false)]
        [Microsoft.Management.Infrastructure.CimInstance[]] 
        $ContentDatabases,

        [parameter(Mandatory = $false)]
        [System.Boolean]
        $AllContentDatabases,

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Setting Shell Admin config"
    
    if ($Members -and (($MembersToInclude) -or ($MembersToExclude))) 
    {
        throw ("Cannot use the Members parameter together with the " + `
               "MembersToInclude or MembersToExclude parameters")
    }

    if ($ContentDatabases) 
    {
        foreach ($contentDatabase in $ContentDatabases) 
        {
            if ($contentDatabase.Members -and (($contentDatabase.MembersToInclude) `
                -or ($contentDatabase.MembersToExclude))) 
            {
                throw ("ContentDatabases: Cannot use the Members parameter " + `
                       "together with the MembersToInclude or " + `
                       "MembersToExclude parameters")
            }

            if (!$contentDatabase.Members `
                -and !$contentDatabase.MembersToInclude `
                -and !$contentDatabase.MembersToExclude) 
            {
                throw ("ContentDatabases: At least one of the following " + `
                       "parameters must be specified: Members, " + `
                       "MembersToInclude, MembersToExclude")
            }
        }
    } 
    else 
    {
        if (!$Members -and !$MembersToInclude -and !$MembersToExclude) 
        {
            throw ("At least one of the following parameters must be " + `
                   "specified: Members, MembersToInclude, MembersToExclude")
        }
    }

    if ($ContentDatabases -and $AllContentDatabases) 
    {
        throw ("Cannot use the ContentDatabases parameter together with the " + `
               "AllContentDatabases parameter")
    }

    $result = Invoke-SPDSCCommand -Credential $InstallAccount `
                                  -Arguments @($PSBoundParameters, $PSScriptRoot) `
                                  -ScriptBlock {
        $params = $args[0]
        $scriptRoot = $args[1]
        
        Import-Module -Name (Join-Path -Path $scriptRoot -ChildPath "MSFT_SPShellAdmins.psm1")

        try 
        {
            $spFarm = Get-SPFarm
        } 
        catch 
        {
            throw ("No local SharePoint farm was detected. Shell admin " + `
                   "settings will not be applied")
        }

        $shellAdmins = Get-SPShellAdmin

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
                                Add-SPShellAdmin -UserName $user
                            } 
                            catch 
                            {
                                throw ("Error while setting the Shell Admin. The Shell " + `
                                       "Admin permissions will not be applied. Error " + `
                                       "details: $($_.Exception.Message)")
                                return
                            }
                        } 
                        elseif ($difference.SideIndicator -eq "<=") 
                        {
                            $user = $difference.InputObject
                            try 
                            {
                                Remove-SPShellAdmin -UserName $user -Confirm:$false
                            } 
                            catch 
                            {
                                throw ("Error while removing the Shell Admin. The Shell Admin " + `
                                       "permissions will not be revoked. Error details: " + `
                                       "$($_.Exception.Message)")
                                return
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
                        Add-SPShellAdmin -UserName $member
                    } 
                    catch 
                    {
                        throw ("Error while setting the Shell Admin. The Shell Admin " + `
                               "permissions will not be applied. Error details: " + `
                               "$($_.Exception.Message)")
                        return
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
                            Add-SPShellAdmin -UserName $member
                        } 
                        catch 
                        {
                            throw ("Error while setting the Shell Admin. The Shell Admin " + `
                                   "permissions will not be applied. Error details: " + `
                                   "$($_.Exception.Message)")
                            return
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
                        Add-SPShellAdmin -UserName $member
                    } 
                    catch 
                    {
                        throw ("Error while setting the Shell Admin. The Shell Admin " + `
                               "permissions will not be applied. Error details: $($_.Exception.Message)")
                        return
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
                            Remove-SPShellAdmin -UserName $member -Confirm:$false
                        } 
                        catch 
                        {
                            throw ("Error while removing the Shell Admin. The Shell Admin " + `
                                   "permissions will not be revoked. Error details: " + `
                                   "$($_.Exception.Message)")
                            return
                        }
                    }
                }
            }
        }

        if ($params.ContentDatabases) 
        {
            Write-Verbose -Message "Processing ContentDatabases parameter"
            # The ContentDatabases parameter is set
            # Compare the configuration against the actual set and correct any issues

            foreach ($contentDatabase in $params.ContentDatabases) 
            {
                # Check if configured database exists, throw error if not
                Write-Verbose -Message "Processing Content Database: $($contentDatabase.Name)"

                $currentCDB = Get-SPContentDatabase | Where-Object -FilterScript { 
                    $_.Name -eq $contentDatabase.Name 
                }
                if ($null -ne $currentCDB) 
                {
                    $dbShellAdmins = Get-SPShellAdmin -database $currentCDB.Id

                    if ($contentDatabase.Members) 
                    {
                        Write-Verbose -Message "Processing Members"
                        if ($dbShellAdmins) 
                        {
                            $differences = Compare-Object -ReferenceObject $contentDatabase.Members `
                                                          -DifferenceObject $dbShellAdmins.UserName
                            foreach ($difference in $differences) 
                            {
                                if ($difference.SideIndicator -eq "<=") 
                                {
                                    $user = $difference.InputObject
                                    try 
                                    {
                                        Add-SPShellAdmin -database $currentCDB.Id -UserName $user
                                    } 
                                    catch 
                                    {
                                        throw ("Error while setting the Shell Admin. The " + `
                                               "Shell Admin permissions will not be applied. " + `
                                               "Error details: $($_.Exception.Message)")
                                        return
                                    }
                                } 
                                elseif ($difference.SideIndicator -eq "=>") 
                                {
                                    $user = $difference.InputObject
                                    try 
                                    {
                                        Remove-SPShellAdmin -Database $currentCDB.Id `
                                                            -UserName $user `
                                                            -Confirm:$false
                                    } 
                                    catch 
                                    {
                                        throw ("Error while removing the Shell Admin. The " + `
                                               "Shell Admin permissions will not be revoked. " + `
                                               "Error details: $($_.Exception.Message)")
                                        return
                                    }
                                }
                            }
                        } 
                        else 
                        {
                            foreach ($member in $contentDatabase.Members) 
                            {
                                try 
                                {
                                    Add-SPShellAdmin -database $currentCDB.Id -UserName $member
                                } 
                                catch 
                                {
                                    throw ("Error while setting the Shell Admin. The Shell " + `
                                           "Admin permissions will not be applied. Error " + `
                                           "details: $($_.Exception.Message)")
                                    return
                                }
                            }
                        }
                    }

                    if ($contentDatabase.MembersToInclude) 
                    {
                        Write-Verbose -Message "Processing MembersToInclude"
                        if ($dbShellAdmins) 
                        {
                            foreach ($member in $contentDatabase.MembersToInclude) 
                            {
                                if (-not $dbShellAdmins.UserName.Contains($member)) 
                                {
                                    try 
                                    {
                                        Add-SPShellAdmin -database $currentCDB.Id -UserName $member
                                    } 
                                    catch 
                                    {
                                        throw ("Error while setting the Shell Admin. The " + `
                                               "Shell Admin permissions will not be applied. " + `
                                               "Error details: $($_.Exception.Message)")
                                        return
                                    }
                                }
                            }
                        } 
                        else 
                        {
                            foreach ($member in $contentDatabase.MembersToInclude) 
                            {
                                try 
                                {
                                    Add-SPShellAdmin -database $currentCDB.Id -UserName $member
                                } 
                                catch 
                                {
                                    throw ("Error while setting the Shell Admin. The Shell " + `
                                           "Admin permissions will not be applied. Error " + `
                                           "details: $($_.Exception.Message)")
                                    return
                                }
                            }
                        }
                    }

                    if ($contentDatabase.MembersToExclude) 
                    {
                        Write-Verbose -Message "Processing MembersToExclude"
                        if ($dbShellAdmins) 
                        {
                            foreach ($member in $contentDatabase.MembersToExclude) 
                            {
                                if ($dbShellAdmins.UserName.Contains($member)) 
                                {
                                    try 
                                    {
                                        Remove-SPShellAdmin -Database $currentCDB.Id `
                                                            -UserName $member `
                                                            -Confirm:$false
                                    } 
                                    catch 
                                    {
                                        throw ("Error while removing the Shell Admin. The " + `
                                               "Shell Admin permissions will not be revoked. " + `
                                               "Error details: $($_.Exception.Message)")
                                        return
                                    }
                                }
                            }
                        }
                    }
                } 
                else 
                {
                    throw "Specified database does not exist: $($contentDatabase.Name)"
                }
            }
        }

        if ($params.AllContentDatabases) 
        {
            Write-Verbose -Message "Processing AllContentDatabases parameter"

            foreach ($contentDatabase in (Get-SPContentDatabase)) 
            {
                $dbShellAdmins = Get-SPShellAdmin -database $contentDatabase.Id
                if ($params.Members) 
                {
                    Write-Verbose -Message "Processing Content Database: $($contentDatabase.Name)"
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
                                        Add-SPShellAdmin -database $contentDatabase.Id -UserName $user
                                    } 
                                    catch 
                                    {
                                        throw ("Error while setting the Shell Admin. The " + `
                                               "Shell Admin permissions will not be applied. " + `
                                               "Error details: $($_.Exception.Message)")
                                        return
                                    }
                                } 
                                elseif ($difference.SideIndicator -eq "<=") 
                                {
                                    $user = $difference.InputObject
                                    try 
                                    {
                                        Remove-SPShellAdmin -Database $contentDatabase.Id `
                                                            -UserName $user `
                                                            -Confirm:$false
                                    }
                                    catch 
                                    {
                                        throw ("Error while removing the Shell Admin. The " + `
                                               "Shell Admin permissions will not be revoked. " + `
                                               "Error details: $($_.Exception.Message)")
                                        return
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
                                Add-SPShellAdmin -database $contentDatabase.Id -UserName $member
                            } 
                            catch 
                            {
                                throw ("Error while setting the Shell Admin. The Shell Admin " + `
                                       "permissions will not be applied. Error details: " + `
                                       "$($_.Exception.Message)")
                                return
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
                                    Add-SPShellAdmin -database $contentDatabase.Id -UserName $member
                                } 
                                catch 
                                {
                                    throw ("Error while setting the Shell Admin. The Shell " + `
                                           "Admin permissions will not be applied. Error " + `
                                           "details: $($_.Exception.Message)")
                                    return
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
                                Add-SPShellAdmin -database $contentDatabase.Id -UserName $member
                            } 
                            catch 
                            {
                                throw ("Error while setting the Shell Admin. The Shell Admin " + `
                                       "permissions will not be applied. Error details: " + `
                                       "$($_.Exception.Message)")
                                return
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
                                    Remove-SPShellAdmin -Database $contentDatabase.Id `
                                                        -UserName $member `
                                                        -Confirm:$false
                                } 
                                catch 
                                {
                                    throw ("Error while removing the Shell Admin. The Shell " + `
                                           "Admin permissions will not be revoked. Error " + `
                                           "details: $($_.Exception.Message)")
                                    return
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
        [parameter(Mandatory = $true)] 
        [System.String]
        $Name,

        [parameter(Mandatory = $false)]
        [System.String[]]
        $Members,

        [parameter(Mandatory = $false)]
        [System.String[]]
        $MembersToInclude,

        [parameter(Mandatory = $false)]
        [System.String[]]
        $MembersToExclude,

        [parameter(Mandatory = $false)]
        [Microsoft.Management.Infrastructure.CimInstance[]] 
        $ContentDatabases,

        [parameter(Mandatory = $false)]
        [System.Boolean]
        $AllContentDatabases,

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Testing Shell Admin settings"

    # Start checking
    $CurrentValues = Get-TargetResource @PSBoundParameters

    if ($null -eq $CurrentValues) 
    { 
        return $false 
    }

    if ($Members) 
    {
        Write-Verbose -Message "Processing Members parameter"
        if (-not $CurrentValues.Members) 
        { 
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
            Write-Verbose -Message "Shell Admins group does not match"
            return $false
        }
    }

    if ($MembersToInclude) 
    {
        Write-Verbose -Message "Processing MembersToInclude parameter"
        if (-not $CurrentValues.Members) 
        { 
            return $false 
        }

        foreach ($member in $MembersToInclude) 
        {
            if (-not($CurrentValues.Members.Contains($member))) 
            {
                Write-Verbose -Message "$member is not a Shell Admin. Set result to false"
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
                    Write-Verbose -Message "$member is a Shell Admin. Set result to false"
                    return $false
                } 
                else 
                {
                    Write-Verbose -Message "$member is not a Shell Admin. Skipping"
                }
            }
        }
    }
    
    if ($AllContentDatabases) 
    {
        # The AllContentDatabases parameter is set
        # Check the Members group against all databases
        Write-Verbose -Message "Processing AllContentDatabases parameter"

        foreach ($contentDatabase in $CurrentValues.ContentDatabases) 
        {
            # Check if configured database exists, throw error if not
            Write-Verbose -Message "Processing Content Database: $($contentDatabase.Name)"

            if ($Members) 
            {
                if (-not $contentDatabase.Members) 
                { 
                    return $false 
                }

                $differences = Compare-Object -ReferenceObject $contentDatabase.Members `
                                              -DifferenceObject $Members

                if ($null -eq $differences) 
                {
                    Write-Verbose -Message "Shell Admins group matches"
                } 
                else 
                {
                    Write-Verbose -Message "Shell Admins group does not match"
                    return $false
                }
            }

            if ($MembersToInclude) 
            {
                if (-not $contentDatabase.Members)
                { 
                    return $false 
                }

                foreach ($member in $MembersToInclude) 
                {
                    if (-not($contentDatabase.Members.Contains($member))) 
                    {
                        Write-Verbose -Message "$member is not a Shell Admin. Set result to false"
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
                if ($contentDatabase.Members) 
                {
                    foreach ($member in $MembersToExclude) 
                    {
                        if ($contentDatabase.Members.Contains($member)) 
                        {
                            Write-Verbose -Message "$member is a Shell Admin. Set result to false"
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

    if ($ContentDatabases) 
    {
        # The ContentDatabases parameter is set
        # Compare the configuration against the actual set
        Write-Verbose -Message "Processing ContentDatabases parameter"

        foreach ($contentDatabase in $ContentDatabases) 
        {
            # Check if configured database exists, throw error if not
            Write-Verbose -Message "Processing Content Database: $($contentDatabase.Name)"

            $currentCDB = $CurrentValues.ContentDatabases | Where-Object -FilterScript { 
                $_.Name -eq $contentDatabase.Name 
            }
            
            if ($null -ne $currentCDB) 
            {
                if ($contentDatabase.Members) 
                {
                    Write-Verbose -Message "Processing Members parameter"
                    if (-not $currentCDB.Members) 
                    { 
                        return $false 
                    }

                    $differences = Compare-Object -ReferenceObject $currentCDB.Members `
                                                  -DifferenceObject $contentDatabase.Members

                    if ($null -eq $differences) 
                    {
                        Write-Verbose -Message "Shell Admins group matches"
                    } 
                    else 
                    {
                        Write-Verbose -Message "Shell Admins group does not match"
                        return $false
                    }
                }

                if ($contentDatabase.MembersToInclude) 
                {
                    Write-Verbose -Message "Processing MembersToInclude parameter"
                    if (-not $currentCDB.Members) 
                    { 
                        return $false 
                    }

                    foreach ($member in $contentDatabase.MembersToInclude) 
                    {
                        if (-not($currentCDB.Members.Contains($member))) 
                        {
                            Write-Verbose -Message "$member is not a Shell Admin. Set result to false"
                            return $false
                        } 
                        else 
                        {
                            Write-Verbose -Message "$member is already a Shell Admin. Skipping"
                        }
                    }
                }

                if ($contentDatabase.MembersToExclude) 
                {
                    Write-Verbose -Message "Processing MembersToExclude parameter"
                    if ($currentCDB.Members) 
                    {
                        foreach ($member in $contentDatabase.MembersToExclude) 
                        {
                            if ($currentCDB.Members.Contains($member)) 
                            {
                                Write-Verbose -Message "$member is a Shell Admin. Set result to false"
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
                throw "Specified database does not exist: $($contentDatabase.Name)"
            }
        }
    }

    return $true
}

Export-ModuleMember -Function *-TargetResource
