[CmdletBinding()]
param(
    [Parameter()]
    [string]
    $SharePointCmdletModule = (Join-Path -Path $PSScriptRoot `
            -ChildPath "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" `
            -Resolve)
)

Import-Module -Name (Join-Path -Path $PSScriptRoot `
        -ChildPath "..\UnitTestHelper.psm1" `
        -Resolve)

$Global:SPDscHelper = New-SPDscUnitTestHelper -SharePointStubModule $SharePointCmdletModule `
    -DscResource "SPIncomingEmailSettings"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        # Initialize tests

        # Mocks for all contexts

        # Test contexts
        Context -Name 'Cannot retrieve instance of mail service' -Fixture {
            $testParams = @{
                IsSingleInstance     = 'Yes'
                Ensure               = 'Present'
                UseAutomaticSettings = $true
                ServerDisplayAddress = "contoso.com"
            }

            Mock -CommandName 'Get-SPServiceInstance' -MockWith {
                return $null
            }

            It 'Should return null values for the Get method' {
                $result = Get-TargetResource @testParams
                $result.Ensure | Should BeNullorEmpty
                $result.UseAutomaticSettings | Should BeNullorEmpty
                $result.UseDirectoryManagementService | Should BeNullorEmpty
                $result.RemoteDirectoryManagementURL | Should BeNullorEmpty
                $result.ServerAddress | Should BeNullorEmpty
                $result.DLsRequireAuthenticatedSenders| Should BeNullorEmpty
                $result.DistributionGroupsEnabled | Should BeNullorEmpty
                $result.ServerDisplayAddress| Should BeNullorEmpty
                $result.DropFolder | Should BeNullorEmpty
            }

            It 'Should return false for the Test method' {
                Test-TargetResource @testParams | Should Be $false
            }

            It 'Should throw and exception for the Set method' {
                { Set-TargetResource @testParams } | Should throw "Error getting the SharePoint Incoming Email Service"
            }
        }

        Context -Name 'When configured values are correct' -Fixture {
            $testParams = @{
                IsSingleInstance               = 'Yes'
                Ensure                         = 'Present'
                UseAutomaticSettings           = $false
                UseDirectoryManagementService  = 'Remote'
                RemoteDirectoryManagementURL   = 'http://server:adminport/_vti_bin/SharepointEmailWS.asmx'
                DLsRequireAuthenticatedSenders = $false
                DistributionGroupsEnabled      = $true
                ServerDisplayAddress           = "contoso.com"
                DropFolder                     = '\\MailServer\SharedFolder'
            }

            Mock -CommandName 'Get-SPServiceInstance' -MockWith {
                $serviceInstance = @{  TypeName = 'Microsoft SharePoint Foundation Incoming E-Mail'
                        Service  = @{
                            TypeName                         = 'Microsoft SharePoint Foundation Incoming E-Mail'
                            Enabled                          = $true
                            DropFolder                       = $testParams.DropFolder
                            UseAutomaticSettings             = $testParams.UseAutomaticSettings
                            ServerDisplayAddress             = $testParams.ServerDisplayAddress
                            ServerAddress                    = $testParams.ServerAddress
                            UseDirectoryManagementService    = $true
                            RemoteDirectoryManagementService = $true
                            DirectoryManagementServiceURL    = $testParams.RemoteDirectoryManagementURL
                            DistributionGroupsEnabled        = $testParams.DistributionGroupsEnabled
                            DLsRequireAuthenticatedSenders   = $testParams.DLsRequireAuthenticatedSenders
                        }
                    }
                return @($serviceInstance)
            }

            It "Should return current values for the Get method" {
                $result = Get-TargetResource @testParams
                $result.Ensure | Should Be $testParams.Ensure
                $result.UseAutomaticSettings | Should Be $testParams.UseAutomaticSettings
                $result.UseDirectoryManagementService | Should Be $testParams.UseDirectoryManagementService
                $result.RemoteDirectoryManagementURL | Should Be $testParams.RemoteDirectoryManagementURL
                $result.DLsRequireAuthenticatedSenders | Should Be $testParams.DLsRequireAuthenticatedSenders
                $result.DistributionGroupsEnabled | Should Be $testParams.DistributionGroupsEnabled
                $result.ServerDisplayAddress | Should Be $testParams.ServerDisplayAddress
                $result.DropFolder | Should Be $testParams.DropFolder
            }

            It "Should return True for the Test method" {
                Test-TargetResource @testParams | Should Be $true            
            }

        }

        Context -Name 'When configured values are incorrect' -Fixture {
            $testParams = @{
                IsSingleInstance               = 'Yes'
                Ensure                         = 'Present'
                UseAutomaticSettings           = $false
                UseDirectoryManagementService  = 'Remote'
                RemoteDirectoryManagementURL   = 'http://server:adminport/_vti_bin/SharepointEmailWS.asmx'
                DLsRequireAuthenticatedSenders = $false
                DistributionGroupsEnabled      = $true
                ServerDisplayAddress           = "contoso.com"
                DropFolder                     = '\\MailServer\SharedFolder'
            }

            Mock -CommandName 'Get-SPServiceInstance' -MockWith {
                $serviceInstance = 
                    @{  TypeName = 'Microsoft SharePoint Foundation Incoming E-Mail'
                        Service  = @{
                            TypeName                         = 'Microsoft SharePoint Foundation Incoming E-Mail'
                            Enabled                          = $true
                            DropFolder                       = $null
                            UseAutomaticSettings             = (-not $testParams.UseAutomaticSettings)
                            ServerDisplayAddress             = $testParams.ServerDisplayAddress
                            ServerAddress                    = $testParams.ServerAddress
                            UseDirectoryManagementService    = $true
                            RemoteDirectoryManagementService = $true
                            DirectoryManagementServiceURL    = $testParams.RemoteDirectoryManagementURL
                            DistributionGroupsEnabled        = $testParams.DistributionGroupsEnabled
                            DLsRequireAuthenticatedSenders   = $testParams.DLsRequireAuthenticatedSenders
                        }
                    }
                $serviceInstance.Service = $serviceInstance.Service  | Add-Member -MemberType ScriptMethod -Name Update -Value {
                    $Global:SPDscUpdateCalled = $true } -PassThru
                return @($serviceInstance)
            }

            It "Should return current values for the Get method" {
                $result = Get-TargetResource @testParams
                $result.Ensure | Should Be $testParams.Ensure
                $result.UseAutomaticSettings | Should Be (-not $testParams.UseAutomaticSettings)
                $result.UseDirectoryManagementService | Should Be $testParams.UseDirectoryManagementService
                $result.RemoteDirectoryManagementURL | Should Be $testParams.RemoteDirectoryManagementURL
                $result.DLsRequireAuthenticatedSenders | Should Be $testParams.DLsRequireAuthenticatedSenders
                $result.DistributionGroupsEnabled | Should Be $testParams.DistributionGroupsEnabled
                $result.ServerDisplayAddress | Should Be $testParams.ServerDisplayAddress
                $result.DropFolder | Should BeNullorEmpty
            }

            It "Should return False for the Test method" {
                Test-TargetResource @testParams | Should Be $false         
            }

            It "Should update settings for the Set method" {
                Set-TargetResource @testParams
                $Global:SPDscUpdateCalled | Should Be $true
            }
        }

        Context -Name 'When enabling Incoming Email, but not specifying required parameters' -Fixture {
            $testParams = @{
                IsSingleInstance               = 'Yes'
                Ensure                         = 'Present'
                UseAutomaticSettings           = $false
                UseDirectoryManagementService  = 'Remote'
                RemoteDirectoryManagementURL   = 'http://server:adminport/_vti_bin/SharepointEmailWS.asmx'
                DLsRequireAuthenticatedSenders = $false
                DistributionGroupsEnabled      = $true
                #ServerDisplayAddress           = "contoso.com"
                DropFolder                     = '\\MailServer\SharedFolder'
            }

            Mock -CommandName 'Get-SPServiceInstance' -MockWith {
                $serviceInstance = 
                    @{  TypeName = 'Microsoft SharePoint Foundation Incoming E-Mail'
                        Service  = @{
                            TypeName                         = 'Microsoft SharePoint Foundation Incoming E-Mail'
                            Enabled                          = $true
                            DropFolder                       = $null
                            UseAutomaticSettings             = $testParams.UseAutomaticSettings
                            ServerDisplayAddress             = $testParams.ServerDisplayAddress
                            ServerAddress                    = $testParams.ServerAddress
                            UseDirectoryManagementService    = $true
                            RemoteDirectoryManagementService = $true
                            DirectoryManagementServiceURL    = $testParams.RemoteDirectoryManagementURL
                            DistributionGroupsEnabled        = $testParams.DistributionGroupsEnabled
                            DLsRequireAuthenticatedSenders   = $testParams.DLsRequireAuthenticatedSenders
                        }
                    }
                $serviceInstance.Service = $serviceInstance.Service  | Add-Member -MemberType ScriptMethod -Name Update -Value {
                    $Global:SPDscUpdateCalled = $true } -PassThru
                return @($serviceInstance)
            }

            It "Should return current values for the Get method" {
                $result = Get-TargetResource @testParams
                $result.Ensure | Should Be $testParams.Ensure
                $result.UseAutomaticSettings | Should Be $testParams.UseAutomaticSettings
                $result.UseDirectoryManagementService | Should Be $testParams.UseDirectoryManagementService
                $result.RemoteDirectoryManagementURL | Should Be $testParams.RemoteDirectoryManagementURL
                $result.DLsRequireAuthenticatedSenders | Should Be $testParams.DLsRequireAuthenticatedSenders
                $result.DistributionGroupsEnabled | Should Be $testParams.DistributionGroupsEnabled
                $result.ServerDisplayAddress | Should Be $testParams.ServerDisplayAddress
                $result.DropFolder | Should BeNullorEmpty
            }

            It "Should return False for the Test method" {
                Test-TargetResource @testParams | Should Be $false         
            }

            It "Should throw an exception for the Set method" {
                { Set-TargetResource @testParams } | Should throw "ServerDisplayAddress parameter must be specified when enabling incoming email"
            }
        }

        Context -Name 'When no RemoteDirectoryManagementURL specified for UseDirectoryManagementService = Remote' -Fixture {
            $testParams = @{
                IsSingleInstance               = 'Yes'
                Ensure                         = 'Present'
                UseAutomaticSettings           = $false
                UseDirectoryManagementService  = 'Remote'
                #RemoteDirectoryManagementURL   = 'http://server:adminport/_vti_bin/SharepointEmailWS.asmx'
                DLsRequireAuthenticatedSenders = $false
                DistributionGroupsEnabled      = $true
                ServerDisplayAddress           = "contoso.com"
                DropFolder                     = '\\MailServer\SharedFolder'
            }

            Mock -CommandName 'Get-SPServiceInstance' -MockWith {
                $serviceInstance = 
                    @{  TypeName = 'Microsoft SharePoint Foundation Incoming E-Mail'
                        Service  = @{
                            TypeName                         = 'Microsoft SharePoint Foundation Incoming E-Mail'
                            Enabled                          = $true
                            DropFolder                       = $null
                            UseAutomaticSettings             = $testParams.UseAutomaticSettings
                            ServerDisplayAddress             = $testParams.ServerDisplayAddress
                            ServerAddress                    = $testParams.ServerAddress
                            UseDirectoryManagementService    = $true
                            RemoteDirectoryManagementService = $true
                            DirectoryManagementServiceURL    = $testParams.RemoteDirectoryManagementURL
                            DistributionGroupsEnabled        = $testParams.DistributionGroupsEnabled
                            DLsRequireAuthenticatedSenders   = $testParams.DLsRequireAuthenticatedSenders
                        }
                    }
                $serviceInstance.Service = $serviceInstance.Service  | Add-Member -MemberType ScriptMethod -Name Update -Value {
                    $Global:SPDscUpdateCalled = $true } -PassThru
                return @($serviceInstance)
            }

            It "Should return current values for the Get method" {
                $result = Get-TargetResource @testParams
                $result.Ensure | Should Be $testParams.Ensure
                $result.UseAutomaticSettings | Should Be $testParams.UseAutomaticSettings
                $result.UseDirectoryManagementService | Should Be $testParams.UseDirectoryManagementService
                $result.RemoteDirectoryManagementURL | Should Be $testParams.RemoteDirectoryManagementURL
                $result.DLsRequireAuthenticatedSenders | Should Be $testParams.DLsRequireAuthenticatedSenders
                $result.DistributionGroupsEnabled | Should Be $testParams.DistributionGroupsEnabled
                $result.ServerDisplayAddress | Should Be $testParams.ServerDisplayAddress
                $result.DropFolder | Should BeNullorEmpty
            }

            It "Should return False for the Test method" {
                Test-TargetResource @testParams | Should Be $false         
            }

            It "Should throw an exception for the Set method" {
                { Set-TargetResource @testParams } | Should throw "RemoteDirectoryManagementURL must be specified only when UseDirectoryManagementService is set to 'Remote'"
            }
        }

        Context -Name 'When AutomaticMode is false, but no DropFolder specified' -Fixture {
            $testParams = @{
                IsSingleInstance               = 'Yes'
                Ensure                         = 'Present'
                UseAutomaticSettings           = $false
                UseDirectoryManagementService  = 'Remote'
                RemoteDirectoryManagementURL   = 'http://server:adminport/_vti_bin/SharepointEmailWS.asmx'
                DLsRequireAuthenticatedSenders = $false
                DistributionGroupsEnabled      = $true
                ServerDisplayAddress           = "contoso.com"
                #DropFolder                     = '\\MailServer\SharedFolder'
            }

            Mock -CommandName 'Get-SPServiceInstance' -MockWith {
                $serviceInstance = 
                    @{  TypeName = 'Microsoft SharePoint Foundation Incoming E-Mail'
                        Service  = @{
                            TypeName                         = 'Microsoft SharePoint Foundation Incoming E-Mail'
                            Enabled                          = $true
                            DropFolder                       = $null
                            UseAutomaticSettings             = $true
                            ServerDisplayAddress             = $testParams.ServerDisplayAddress
                            ServerAddress                    = $testParams.ServerAddress
                            UseDirectoryManagementService    = $true
                            RemoteDirectoryManagementService = $true
                            DirectoryManagementServiceURL    = $testParams.RemoteDirectoryManagementURL
                            DistributionGroupsEnabled        = $testParams.DistributionGroupsEnabled
                            DLsRequireAuthenticatedSenders   = $testParams.DLsRequireAuthenticatedSenders
                        }
                    }
                $serviceInstance.Service = $serviceInstance.Service  | Add-Member -MemberType ScriptMethod -Name Update -Value {
                    $Global:SPDscUpdateCalled = $true } -PassThru
                return @($serviceInstance)
            }

            It "Should return current values for the Get method" {
                $result = Get-TargetResource @testParams
                $result.Ensure | Should Be $testParams.Ensure
                $result.UseAutomaticSettings | Should Be $true
                $result.UseDirectoryManagementService | Should Be $testParams.UseDirectoryManagementService
                $result.RemoteDirectoryManagementURL | Should Be $testParams.RemoteDirectoryManagementURL
                $result.DLsRequireAuthenticatedSenders | Should Be $testParams.DLsRequireAuthenticatedSenders
                $result.DistributionGroupsEnabled | Should Be $testParams.DistributionGroupsEnabled
                $result.ServerDisplayAddress | Should Be $testParams.ServerDisplayAddress
                $result.DropFolder | Should BeNullorEmpty
            }

            It "Should return False for the Test method" {
                Test-TargetResource @testParams | Should Be $false         
            }

            It "Should throw an exception for the Set method" {
                { Set-TargetResource @testParams } | Should throw "DropFolder parameter must be specified when not using Automatic Mode"
            }
        }

        Context -Name 'When AutomaticMode is true, but a DropFolder was specified' -Fixture {
            $testParams = @{
                IsSingleInstance               = 'Yes'
                Ensure                         = 'Present'
                UseAutomaticSettings           = $true
                UseDirectoryManagementService  = 'Remote'
                RemoteDirectoryManagementURL   = 'http://server:adminport/_vti_bin/SharepointEmailWS.asmx'
                DLsRequireAuthenticatedSenders = $false
                DistributionGroupsEnabled      = $true
                ServerDisplayAddress           = "contoso.com"
                DropFolder                     = '\\MailServer\SharedFolder'
            }

            Mock -CommandName 'Get-SPServiceInstance' -MockWith {
                $serviceInstance = 
                    @{  TypeName = 'Microsoft SharePoint Foundation Incoming E-Mail'
                        Service  = @{
                            TypeName                         = 'Microsoft SharePoint Foundation Incoming E-Mail'
                            Enabled                          = $true
                            DropFolder                       = $null
                            UseAutomaticSettings             = $testParams.UseAutomaticSettings
                            ServerDisplayAddress             = $testParams.ServerDisplayAddress
                            ServerAddress                    = $testParams.ServerAddress
                            UseDirectoryManagementService    = $true
                            RemoteDirectoryManagementService = $true
                            DirectoryManagementServiceURL    = $testParams.RemoteDirectoryManagementURL
                            DistributionGroupsEnabled        = $testParams.DistributionGroupsEnabled
                            DLsRequireAuthenticatedSenders   = $testParams.DLsRequireAuthenticatedSenders
                        }
                    }
                $serviceInstance.Service = $serviceInstance.Service  | Add-Member -MemberType ScriptMethod -Name Update -Value {
                    $Global:SPDscUpdateCalled = $true } -PassThru
                return @($serviceInstance)
            }

            It "Should return current values for the Get method" {
                $result = Get-TargetResource @testParams
                $result.Ensure | Should Be $testParams.Ensure
                $result.UseAutomaticSettings | Should Be $testParams.UseAutomaticSettings
                $result.UseDirectoryManagementService | Should Be $testParams.UseDirectoryManagementService
                $result.RemoteDirectoryManagementURL | Should Be $testParams.RemoteDirectoryManagementURL
                $result.DLsRequireAuthenticatedSenders | Should Be $testParams.DLsRequireAuthenticatedSenders
                $result.DistributionGroupsEnabled | Should Be $testParams.DistributionGroupsEnabled
                $result.ServerDisplayAddress | Should Be $testParams.ServerDisplayAddress
                $result.DropFolder | Should BeNullorEmpty
            }

            It "Should return False for the Test method" {
                Test-TargetResource @testParams | Should Be $false         
            }

            It "Should throw an exception for the Set method" {
                { Set-TargetResource @testParams } | Should throw "DropFolder parameter is not valid when using Automatic Mode"
            }
        }

    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
