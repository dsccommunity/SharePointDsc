[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param
(
    [Parameter()]
    [string]
    $SharePointCmdletModule = (Join-Path -Path $PSScriptRoot `
            -ChildPath "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" `
            -Resolve)
)

$script:DSCModuleName = 'SharePointDsc'
$script:DSCResourceName = 'SPDistributedCacheService'
$script:DSCResourceFullName = 'MSFT_' + $script:DSCResourceName

function Invoke-TestSetup
{
    try
    {
        Import-Module -Name DscResource.Test -Force

        Import-Module -Name (Join-Path -Path $PSScriptRoot `
                -ChildPath "..\UnitTestHelper.psm1" `
                -Resolve)

        $Global:SPDscHelper = New-SPDscUnitTestHelper -SharePointStubModule $SharePointCmdletModule `
            -DscResource $script:DSCResourceName `
            -IncludeDistributedCacheStubs
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
    }

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:DSCModuleName `
        -DSCResourceName $script:DSCResourceFullName `
        -ResourceType 'Mof' `
        -TestType 'Unit'
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Invoke-TestSetup

try
{
    InModuleScope -ModuleName $script:DSCResourceFullName -ScriptBlock {
        Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
            BeforeAll {
                Invoke-Command -Scriptblock $Global:SPDscHelper.InitializeScript -NoNewScope

                # Mocks for all contexts
                Mock -CommandName Use-CacheCluster -MockWith { }
                Mock -CommandName Get-WmiObject -MockWith {
                    return @{
                        StartName = $testParams.ServiceAccount
                    }
                }
                Mock -CommandName Get-NetFirewallRule -MockWith {
                    return @{ }
                }
                Mock -CommandName Get-NetFirewallRule -MockWith {
                    return @{ }
                }
                Mock -CommandName Enable-NetFirewallRule -MockWith { }
                Mock -CommandName New-NetFirewallRule -MockWith { }
                Mock -CommandName Disable-NetFirewallRule -MockWith { }
                Mock -CommandName Add-SPDistributedCacheServiceInstance -MockWith { }
                Mock -CommandName Update-SPDistributedCacheSize -MockWith { }
                Mock -CommandName Get-SPManagedAccount -MockWith {
                    return @{ }
                }
                Mock -CommandName Add-SPDscUserToLocalAdmin -MockWith { }
                Mock -CommandName Test-SPDscUserIsLocalAdmin -MockWith {
                    return $false
                }
                Mock -CommandName Remove-SPDSCUserToLocalAdmin -MockWith { }
                Mock -CommandName Restart-Service -MockWith { }
                Mock -CommandName Get-SPFarm -MockWith {
                    return @{
                        Services = @(@{
                                Name            = "AppFabricCachingService"
                                ProcessIdentity = New-Object -TypeName "Object" |
                                    Add-Member -MemberType NoteProperty `
                                        -Name ManagedAccount `
                                        -Value $null `
                                        -PassThru |
                                        Add-Member -MemberType NoteProperty `
                                            -Name CurrentIdentityType `
                                            -Value $null `
                                            -PassThru |
                                            Add-Member -MemberType ScriptMethod `
                                                -Name Update `
                                                -Value { $global:SPDscUpdatedProcessID = $true } `
                                                -PassThru |
                                                Add-Member -MemberType ScriptMethod `
                                                    -Name Deploy `
                                                    -Value { } `
                                                    -PassThru
                            })
                    } }
                Mock -CommandName Stop-SPServiceInstance -MockWith {
                    $Global:SPDscDCacheOnline = $false
                }
                Mock -CommandName Start-SPServiceInstance -MockWith {
                    $Global:SPDscDCacheOnline = $true
                }

                Mock -CommandName Get-SPServiceInstance -MockWith {
                    if ($Global:SPDscDCacheOnline -eq $false)
                    {
                        return @(New-Object -TypeName "Object" |
                                Add-Member -MemberType NoteProperty `
                                    -Name Status `
                                    -Value "Disabled" `
                                    -PassThru |
                                    Add-Member -MemberType NoteProperty `
                                        -Name Service `
                                        -Value "SPDistributedCacheService Name=AppFabricCachingService" `
                                        -PassThru |
                                        Add-Member -MemberType NoteProperty `
                                            -Name Server `
                                            -Value @{
                                            Name = $env:COMPUTERNAME
                                        } -PassThru |
                                            Add-Member -MemberType ScriptMethod `
                                                -Name Delete `
                                                -Value { } `
                                                -PassThru |
                                                Add-Member -MemberType ScriptMethod `
                                                    -Name GetType `
                                                    -Value {
                                                    New-Object -TypeName "Object" |
                                                        Add-Member -MemberType NoteProperty `
                                                            -Name Name `
                                                            -Value "SPDistributedCacheServiceInstance" `
                                                            -PassThru
                                                    } -PassThru -Force)
                    }
                    else
                    {
                        return @(New-Object -TypeName "Object" |
                                Add-Member -MemberType NoteProperty `
                                    -Name Status `
                                    -Value "Online" `
                                    -PassThru |
                                    Add-Member -MemberType NoteProperty `
                                        -Name Service `
                                        -Value "SPDistributedCacheService Name=AppFabricCachingService" `
                                        -PassThru |
                                        Add-Member -MemberType NoteProperty `
                                            -Name Server `
                                            -Value @{
                                            Name = $env:COMPUTERNAME
                                        } -PassThru |
                                            Add-Member -MemberType ScriptMethod `
                                                -Name Delete `
                                                -Value { } `
                                                -PassThru |
                                                Add-Member -MemberType ScriptMethod `
                                                    -Name GetType `
                                                    -Value {
                                                    New-Object -TypeName "Object" |
                                                        Add-Member -MemberType NoteProperty `
                                                            -Name Name `
                                                            -Value "SPDistributedCacheServiceInstance" `
                                                            -PassThru
                                                    } -PassThru -Force)
                    }
                }

                function Add-SPDscEvent
                {
                    param (
                        [Parameter(Mandatory = $true)]
                        [System.String]
                        $Message,

                        [Parameter(Mandatory = $true)]
                        [System.String]
                        $Source,

                        [Parameter()]
                        [ValidateSet('Error', 'Information', 'FailureAudit', 'SuccessAudit', 'Warning')]
                        [System.String]
                        $EntryType,

                        [Parameter()]
                        [System.UInt32]
                        $EventID
                    )
                }
            }

            # Test contexts
            Context -Name "Distributed cache is not configured" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                = "AppFabricCache"
                        Ensure              = "Present"
                        CacheSizeInMB       = 1024
                        ServiceAccount      = "DOMAIN\user"
                        CreateFirewallRules = $true
                    }

                    Mock -CommandName Use-CacheCluster -MockWith {
                        throw [Exception] "ERRPS001 Error in reading provider and connection string values."
                    }
                    $Global:SPDscDCacheOnline = $false
                }

                It "Should return null from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should set up the cache correctly" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Add-SPDistributedCacheServiceInstance
                }
            }

            Context -Name "Distributed cache is not configured, waiting for stop of DC" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                = "AppFabricCache"
                        Ensure              = "Present"
                        CacheSizeInMB       = 1024
                        ServiceAccount      = "DOMAIN\user"
                        CreateFirewallRules = $true
                    }

                    Mock -CommandName Start-Sleep -MockWith { }

                    Mock -CommandName Use-CacheCluster -MockWith {
                        throw [Exception] "ERRPS001 Error in reading provider and connection string values."
                    }
                    Mock -CommandName Stop-SPServiceInstance -MockWith { }
                    Mock -CommandName Start-SPServiceInstance -MockWith { }

                    Mock -CommandName Get-SPServiceInstance -MockWith {
                        switch ($Global:SPDscRunCount)
                        {
                            { 0, 3, 4, 5 -contains $_ }
                            {
                                $Global:SPDscRunCount++
                                return @(New-Object -TypeName "Object" |
                                        Add-Member -MemberType NoteProperty `
                                            -Name Status `
                                            -Value "Disabled" `
                                            -PassThru |
                                            Add-Member -MemberType NoteProperty `
                                                -Name Service `
                                                -Value "SPDistributedCacheService Name=AppFabricCachingService" `
                                                -PassThru |
                                                Add-Member -MemberType NoteProperty `
                                                    -Name Server `
                                                    -Value @{
                                                    Name = $env:COMPUTERNAME
                                                } -PassThru |
                                                    Add-Member -MemberType ScriptMethod `
                                                        -Name Delete `
                                                        -Value { } `
                                                        -PassThru |
                                                        Add-Member -MemberType ScriptMethod `
                                                            -Name GetType `
                                                            -Value {
                                                            New-Object -TypeName "Object" |
                                                                Add-Member -MemberType NoteProperty `
                                                                    -Name Name `
                                                                    -Value "SPDistributedCacheServiceInstance" `
                                                                    -PassThru
                                                            } -PassThru -Force)
                            }
                            { 1, 2, 6, 7 -contains $_ }
                            {
                                $Global:SPDscRunCount = $Global:SPDscRunCount + 1
                                return @(New-Object -TypeName "Object" |
                                        Add-Member -MemberType NoteProperty `
                                            -Name Status `
                                            -Value "Online" `
                                            -PassThru |
                                            Add-Member -MemberType NoteProperty `
                                                -Name Service `
                                                -Value "SPDistributedCacheService Name=AppFabricCachingService" `
                                                -PassThru |
                                                Add-Member -MemberType NoteProperty `
                                                    -Name Server `
                                                    -Value @{
                                                    Name = $env:COMPUTERNAME
                                                } -PassThru |
                                                    Add-Member -MemberType ScriptMethod `
                                                        -Name Delete `
                                                        -Value { } `
                                                        -PassThru |
                                                        Add-Member -MemberType ScriptMethod `
                                                            -Name GetType `
                                                            -Value {
                                                            New-Object -TypeName "Object" |
                                                                Add-Member -MemberType NoteProperty `
                                                                    -Name Name `
                                                                    -Value "SPDistributedCacheServiceInstance" `
                                                                    -PassThru
                                                            } -PassThru -Force)
                            }
                        }
                    }
                }

                It "Should set up the cache correctly" {
                    $Global:SPDscRunCount = 0
                    Set-TargetResource @testParams
                    Assert-MockCalled Add-SPDistributedCacheServiceInstance
                }
            }

            Context -Name "Distributed cache is not configured, ServerProvisionOrder specified" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                 = "AppFabricCache"
                        Ensure               = "Present"
                        CacheSizeInMB        = 1024
                        ServiceAccount       = "DOMAIN\user"
                        ServerProvisionOrder = "Server1", $env:COMPUTERNAME
                        CreateFirewallRules  = $true
                    }

                    Mock -CommandName Start-Sleep -MockWith { }

                    Mock -CommandName Get-CimInstance -MockWith {
                        return @{
                            Domain = "contoso.com"
                        }
                    }
                    Mock -CommandName Use-CacheCluster -MockWith {
                        throw [Exception] "ERRPS001 Error in reading provider and connection string values."
                    }
                    $Global:SPDscDCacheOnline = $false

                    Mock -CommandName Get-SPServiceInstance -MockWith {
                        $returnval = @{
                            Status = "Online"
                        }

                        $returnval = $returnval | Add-Member -MemberType ScriptMethod -Name GetType -Value {
                            return @{ Name = "SPDistributedCacheServiceInstance" }
                        } -PassThru -Force

                        return $returnval
                    } -ParameterFilter { $Server -eq "Server1" }
                }

                It "Should return null from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should set up the cache correctly" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Add-SPDistributedCacheServiceInstance
                }
            }

            Context -Name "Distributed cache is not configured, ServerProvisionOrder specified" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                 = "AppFabricCache"
                        Ensure               = "Present"
                        CacheSizeInMB        = 1024
                        ServiceAccount       = "DOMAIN\user"
                        ServerProvisionOrder = "Server1", "Server2"
                        CreateFirewallRules  = $true
                    }

                    Mock -CommandName Start-Sleep -MockWith { }

                    Mock -CommandName Get-CimInstance -MockWith {
                        return @{
                            Domain = "contoso.com"
                        }
                    }
                    Mock -CommandName Use-CacheCluster -MockWith {
                        throw [Exception] "ERRPS001 Error in reading provider and connection string values."
                    }
                    $Global:SPDscDCacheOnline = $false

                    Mock -CommandName Get-SPServiceInstance -MockWith {
                        $returnval = @{
                            Status = "Online"
                        }

                        $returnval = $returnval | Add-Member -MemberType ScriptMethod -Name GetType -Value {
                            return @{ Name = "SPDistributedCacheServiceInstance" }
                        } -PassThru -Force

                        return $returnval
                    } -ParameterFilter { $Server -eq "Server1" -or $Server -eq "Server2" }
                }

                It "Should set up the cache correctly" {
                    { Set-TargetResource @testParams } | Should -Throw "The server $($env:COMPUTERNAME) was not found in the ServerProvisionOrder array of Distributed Cache server(s).  The server must be included in ServerProvisionOrder or Ensure equal to Absent."
                }
            }

            Context -Name "Distributed cache is configured correctly and running as required" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                = "AppFabricCache"
                        Ensure              = "Present"
                        CacheSizeInMB       = 1024
                        ServiceAccount      = "DOMAIN\user"
                        CreateFirewallRules = $true
                    }

                    $Global:SPDscDCacheOnline = $true

                    Mock -CommandName Get-AFCacheHostConfiguration -MockWith {
                        return @{
                            Size = $testParams.CacheSizeInMB
                        }
                    }
                    Mock -CommandName Get-CacheHost -MockWith {
                        return @{
                            PortNo = 22233
                        }
                    }

                    Mock -CommandName Get-CimInstance -MockWith {
                        return @{
                            StartName = "DOMAIN\user"
                        }
                    }
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "Distributed cache is configured but with the incorrect service account" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                = "AppFabricCache"
                        Ensure              = "Present"
                        CacheSizeInMB       = 1024
                        ServiceAccount      = "DOMAIN\user"
                        CreateFirewallRules = $true
                    }

                    $Global:SPDscDCacheOnline = $true

                    Mock -CommandName Get-AFCacheHostConfiguration -MockWith {
                        return @{
                            Size = $testParams.CacheSizeInMB
                        }
                    }
                    Mock -CommandName Get-CacheHost -MockWith {
                        return @{
                            PortNo = 22233
                        }
                    }

                    Mock -CommandName Get-CimInstance -MockWith {
                        return @{
                            StartName = "DOMAIN\wronguser"
                        }
                    }
                }

                It "Should return DOMAIN\wronguser from the get method" {
                    (Get-TargetResource @testParams).ServiceAccount | Should -Be "DOMAIN\wronguser"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                $global:SPDscUpdatedProcessID = $false
                It "Should correct the service account in the set method" {
                    Set-TargetResource @testParams
                    $global:SPDscUpdatedProcessID | Should -Be $true
                }
            }

            Context -Name "Distributed cache is configured but the cachesize is incorrect" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                = "AppFabricCache"
                        Ensure              = "Present"
                        CacheSizeInMB       = 1024
                        ServiceAccount      = "DOMAIN\user"
                        CreateFirewallRules = $true
                    }

                    $Global:SPDscDCacheOnline = $true

                    Mock -CommandName Get-AFCacheHostConfiguration -MockWith {
                        return @{
                            Size = 2048
                        }
                    }
                    Mock -CommandName Get-CacheHost -MockWith {
                        return @{
                            PortNo = 22233
                        }
                    }
                    Mock -CommandName Start-Sleep -MockWith { }

                    Mock -CommandName Get-SPServiceInstance -MockWith {
                        switch ($Global:SPDscRunCount)
                        {
                            { 0, 3, 4, 5 -contains $_ }
                            {
                                $Global:SPDscRunCount++
                                return @(New-Object -TypeName "Object" |
                                        Add-Member -MemberType NoteProperty `
                                            -Name Status `
                                            -Value "Disabled" `
                                            -PassThru |
                                            Add-Member -MemberType NoteProperty `
                                                -Name Service `
                                                -Value "SPDistributedCacheService Name=AppFabricCachingService" `
                                                -PassThru |
                                                Add-Member -MemberType NoteProperty `
                                                    -Name Server `
                                                    -Value @{
                                                    Name = $env:COMPUTERNAME
                                                } -PassThru |
                                                    Add-Member -MemberType ScriptMethod `
                                                        -Name Delete `
                                                        -Value { } `
                                                        -PassThru |
                                                        Add-Member -MemberType ScriptMethod `
                                                            -Name GetType `
                                                            -Value {
                                                            New-Object -TypeName "Object" |
                                                                Add-Member -MemberType NoteProperty `
                                                                    -Name Name `
                                                                    -Value "SPDistributedCacheServiceInstance" `
                                                                    -PassThru
                                                            } -PassThru -Force)
                            }
                            { 1, 2, 6, 7 -contains $_ }
                            {
                                $Global:SPDscRunCount = $Global:SPDscRunCount + 1
                                return @(New-Object -TypeName "Object" |
                                        Add-Member -MemberType NoteProperty `
                                            -Name Status `
                                            -Value "Online" `
                                            -PassThru |
                                            Add-Member -MemberType NoteProperty `
                                                -Name Service `
                                                -Value "SPDistributedCacheService Name=AppFabricCachingService" `
                                                -PassThru |
                                                Add-Member -MemberType NoteProperty `
                                                    -Name Server `
                                                    -Value @{
                                                    Name = $env:COMPUTERNAME
                                                } -PassThru |
                                                    Add-Member -MemberType ScriptMethod `
                                                        -Name Delete `
                                                        -Value { } `
                                                        -PassThru |
                                                        Add-Member -MemberType ScriptMethod `
                                                            -Name GetType `
                                                            -Value {
                                                            New-Object -TypeName "Object" |
                                                                Add-Member -MemberType NoteProperty `
                                                                    -Name Name `
                                                                    -Value "SPDistributedCacheServiceInstance" `
                                                                    -PassThru
                                                            } -PassThru -Force)
                            }
                        }
                    }
                }

                It "Should return CacheSizeInMB = 2048 from the get method" {
                    $Global:SPDscRunCount = 0
                    (Get-TargetResource @testParams).CacheSizeInMB | Should -Be 2048
                }

                It "Should configure the distributed cache service cache size" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Update-SPDistributedCacheSize
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }
            }

            Context -Name "Distributed cache is configured but the required firewall rules are not deployed" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                = "AppFabricCache"
                        Ensure              = "Present"
                        CacheSizeInMB       = 1024
                        ServiceAccount      = "DOMAIN\user"
                        CreateFirewallRules = $true
                    }

                    $Global:SPDscDCacheOnline = $true

                    Mock -CommandName Get-NetFirewallRule -MockWith {
                        return $null
                    }
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should configure the firewall rules" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Enable-NetFirewallRule
                }
            }

            Context -Name "Distributed cache is confgured but should not be running on this machine" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                = "AppFabricCache"
                        Ensure              = "Absent"
                        CacheSizeInMB       = 1024
                        ServiceAccount      = "DOMAIN\user"
                        CreateFirewallRules = $true
                    }

                    $Global:SPDscDCacheOnline = $true

                    Mock -CommandName Get-AFCacheHostConfiguration -MockWith {
                        return @{
                            Size = $testParams.CacheSizeInMB
                        }
                    }
                    Mock -CommandName Get-CacheHost -MockWith {
                        return @{
                            PortNo = 22233
                        }
                    }
                    Mock -CommandName Get-NetFirewallRule -MockWith {
                        return @{ }
                    }
                    Mock -CommandName Remove-SPDistributedCacheServiceInstance -MockWith { }
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "shuts down the distributed cache service" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Remove-SPDistributedCacheServiceInstance
                    Assert-MockCalled Disable-NetFirewallRule
                }
            }

            Context -Name "Running ReverseDsc Export" -Fixture {
                BeforeAll {
                    Import-Module (Join-Path -Path (Split-Path -Path (Get-Module SharePointDsc -ListAvailable).Path -Parent) -ChildPath "Modules\SharePointDSC.Reverse\SharePointDSC.Reverse.psm1")

                    Mock -CommandName Write-Host -MockWith { }

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Name                 = "AppFabricCachingService"
                            CacheSizeInMB        = 8192
                            ServiceAccount       = "DEMO\ServiceAccount"
                            ServerProvisionOrder = @("Server1", "Server2")
                            CreateFirewallRules  = $true
                            Ensure               = "Present"
                        }
                    }

                    if ($null -eq (Get-Variable -Name 'spFarmAccount' -ErrorAction SilentlyContinue))
                    {
                        $mockPassword = ConvertTo-SecureString -String "password" -AsPlainText -Force
                        $Global:spFarmAccount = New-Object -TypeName System.Management.Automation.PSCredential ("contoso\spfarm", $mockPassword)
                    }

                    $result = @'
        SPDistributedCacheService [0-9A-Fa-f]{8}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{12}
        {
            CacheSizeInMB        = 8192;
            CreateFirewallRules  = \$True;
            Ensure               = "Present";
            Name                 = "AppFabricCachingService";
            PsDscRunAsCredential = \$Credsspfarm;
            ServiceAccount       = "DEMO\\ServiceAccount";
        }

'@
                }

                It "Should return valid DSC block from the Export method" {
                    Export-TargetResource | Should -Match $result
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
