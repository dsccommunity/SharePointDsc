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
        Mock -CommandName 'Get-SPServiceInstance' -MockWith {
            $serviceInstance =
            @{
                Service  = @{
                    Enabled                          = $mock.Enabled
                    DropFolder                       = $mock.DropFolder
                    UseAutomaticSettings             = $mock.UseAutomaticSettings
                    ServerDisplayAddress             = $mock.ServerDisplayAddress
                    ServerAddress                    = $mock.ServerAddress
                    UseDirectoryManagementService    = $mock.UseDirectoryManagementService
                    RemoteDirectoryManagementService = $mock.RemoteDirectoryManagementService
                    DirectoryManagementServiceURL    = $mock.DirectoryManagementServiceURL
                    DistributionGroupsEnabled        = $mock.DistributionGroupsEnabled
                    DLsRequireAuthenticatedSenders   = $mock.DLsRequireAuthenticatedSenders
                }
            }
            $serviceInstance = $serviceInstance  | Add-Member -MemberType ScriptMethod -Name GetType -Value {
                return @{ FullName = "Microsoft.SharePoint.Administration.SPIncomingEmailServiceInstance"} } -force -PassThru
            $serviceInstance.Service = $serviceInstance.Service | Add-Member -MemberType ScriptMethod -Name GetType -Value {
                return @{ FullName = "Microsoft.SharePoint.Administration.SPIncomingEmailService"} } -force -PassThru
            $serviceInstance.Service = $serviceInstance.Service  | Add-Member -MemberType ScriptMethod -Name Update -Value {
                $Global:SPDscUpdateCalled = $true } -PassThru
            return @($serviceInstance)
        }

        # Test contexts
        Context -Name 'Cannot retrieve instance of mail service' -Fixture {
            $testParams = @{
                IsSingleInstance     = 'Yes'
                Ensure               = 'Present'
                UseAutomaticSettings = $true
                ServerDisplayAddress = "contoso.com"
            }

            Mock -CommandName 'Get-SPServiceInstance' -MockWith {
                $serviceInstance = @{}
                $serviceInstance = $serviceInstance  | Add-Member -MemberType ScriptMethod -Name GetType -Value {
                    return $null } -force -PassThru
                return @($serviceInstance)
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

            $mock = @{
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

            $mock = @{
                Enabled                          = $true
                DropFolder                       = $null
                UseAutomaticSettings             = (-not $testParams.UseAutomaticSettings)
                ServerDisplayAddress             = $testParams.ServerDisplayAddress
                ServerAddress                    = $testParams.ServerAddress
                UseDirectoryManagementService    = $true
                RemoteDirectoryManagementService = $false
                DirectoryManagementServiceURL    = $null
                DistributionGroupsEnabled        = $testParams.DistributionGroupsEnabled
                DLsRequireAuthenticatedSenders   = $testParams.DLsRequireAuthenticatedSenders
            }

            It "Should return current values for the Get method" {
                $result = Get-TargetResource @testParams
                $result.Ensure | Should Be $testParams.Ensure
                $result.UseAutomaticSettings | Should Be (-not $testParams.UseAutomaticSettings)
                $result.UseDirectoryManagementService | Should Be $true
                $result.RemoteDirectoryManagementURL | Should BeNullorEmpty
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

        Context -Name 'When service is disabled, but should be enabled' -Fixture {
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

            $mock = @{
                Enabled                          = $false
                DropFolder                       = $null
                UseAutomaticSettings             = $testParams.UseAutomaticSettings
                ServerDisplayAddress             = $null
                ServerAddress                    = $null
                UseDirectoryManagementService    = $false
                RemoteDirectoryManagementService = $false
                DirectoryManagementServiceURL    = $null
                DistributionGroupsEnabled        = $false
                DLsRequireAuthenticatedSenders   = $false
            }

            It "Should return null values for the Get method" {
                $result = Get-TargetResource @testParams
                $result.Ensure | Should Be 'Absent'
                $result.UseAutomaticSettings | Should BeNullorEmpty
                $result.UseDirectoryManagementService | Should BeNullorEmpty
                $result.RemoteDirectoryManagementURL | Should BeNullorEmpty
                $result.DLsRequireAuthenticatedSenders | Should BeNullorEmpty
                $result.DistributionGroupsEnabled | Should BeNullorEmpty
                $result.ServerDisplayAddress | Should BeNullorEmpty
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

        Context -Name 'When service is enabled, but should be disabled' -Fixture {
            $testParams = @{
                IsSingleInstance               = 'Yes'
                Ensure                         = 'Absent'
            }

            $mock = @{
                Enabled                          = $true
                DropFolder                       = $null
                UseAutomaticSettings             = $true
                ServerDisplayAddress             = 'contoso.com'
                ServerAddress                    = $null
                UseDirectoryManagementService    = $false
                RemoteDirectoryManagementService = $false
                DirectoryManagementServiceURL    = $null
                DistributionGroupsEnabled        = $false
                DLsRequireAuthenticatedSenders   = $false
            }

            It "Should return current values for the Get method" {
                $result = Get-TargetResource @testParams
                $result.Ensure | Should Be 'Present'
                $result.UseAutomaticSettings | Should Be $mock.UseAutomaticSettings
                $result.UseDirectoryManagementService | Should Be 'No'
                $result.RemoteDirectoryManagementURL | Should BeNullorEmpty
                $result.DLsRequireAuthenticatedSenders | Should Be $mock.DLsRequireAuthenticatedSenders
                $result.DistributionGroupsEnabled | Should Be $mock.DistributionGroupsEnabled
                $result.ServerDisplayAddress | Should Be $mock.ServerDisplayAddress
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

        Context -Name 'When switching from manual to automatic settings' -Fixture {
            $testParams = @{
                IsSingleInstance               = 'Yes'
                Ensure                         = 'Present'
                UseAutomaticSettings           = $true
                UseDirectoryManagementService  = 'No'
                ServerDisplayAddress           = "contoso.com"
            }

            $mock = @{
                Enabled                          = $true
                DropFolder                       = '\\MailServer\SharedFolder'
                UseAutomaticSettings             = (-not $testParams.UseAutomaticSettings)
                ServerDisplayAddress             = $testParams.ServerDisplayAddress
                ServerAddress                    = $null
                UseDirectoryManagementService    = $false
                RemoteDirectoryManagementService = $false
                DirectoryManagementServiceURL    = $null
                DistributionGroupsEnabled        = $false
                DLsRequireAuthenticatedSenders   = $false
            }

            It "Should return current values for the Get method" {
                $result = Get-TargetResource @testParams
                $result.Ensure | Should Be $testParams.Ensure
                $result.UseAutomaticSettings | Should Be (-not $testParams.UseAutomaticSettings)
                $result.UseDirectoryManagementService | Should Be $testParams.UseDirectoryManagementService
                $result.RemoteDirectoryManagementURL | Should BeNullorEmpty
                $result.DLsRequireAuthenticatedSenders | Should Be $mock.DLsRequireAuthenticatedSenders
                $result.DistributionGroupsEnabled | Should Be $mock.DistributionGroupsEnabled
                $result.ServerDisplayAddress | Should Be $testParams.ServerDisplayAddress
                $result.DropFolder | Should Be $mock.DropFolder
            }

            It "Should return False for the Test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should update settings for the Set method" {
                Set-TargetResource @testParams
                $Global:SPDscUpdateCalled | Should Be $true
            }
        }

        Context -Name 'When updating ServerAddress and Directory Managment Service' -Fixture {
            $testParams = @{
                IsSingleInstance               = 'Yes'
                Ensure                         = 'Present'
                UseAutomaticSettings           = $false
                UseDirectoryManagementService  = 'Yes'
                ServerDisplayAddress           = "contoso.com"
                ServerAddress                  = "mail.contoso.com"
                DropFolder                     = '\\MailServer\SharedFolder'
            }

            $mock = @{
                Enabled                          = $true
                DropFolder                       = $testParams.DropFolder
                UseAutomaticSettings             = $testParams.UseAutomaticSettings
                ServerDisplayAddress             = $testParams.ServerDisplayAddress
                ServerAddress                    = "oldserver.contoso.com"
                UseDirectoryManagementService    = $true
                RemoteDirectoryManagementService = $true
                DirectoryManagementServiceURL    = 'http://server:adminport/_vti_bin/SharepointEmailWS.asmx'
                DistributionGroupsEnabled        = $false
                DLsRequireAuthenticatedSenders   = $false
            }

            It "Should return null values for the Get method" {
                $result = Get-TargetResource @testParams
                $result.Ensure | Should Be 'Present'
                $result.UseAutomaticSettings | Should Be $mock.UseAutomaticSettings
                $result.UseDirectoryManagementService | Should Be 'Remote'
                $result.RemoteDirectoryManagementURL | Should Be $mock.DirectoryManagementServiceURL
                $result.DLsRequireAuthenticatedSenders | Should Be $mock.DLsRequireAuthenticatedSenders
                $result.DistributionGroupsEnabled | Should Be $mock.DistributionGroupsEnabled
                $result.ServerDisplayAddress | Should Be $mock.ServerDisplayAddress
                $result.ServerAddress | Should Be $mock.ServerAddress
                $result.DropFolder | Should Be $mock.DropFolder
            }

            It "Should return False for the Test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should update settings for the Set method" {
                Set-TargetResource @testParams
                $Global:SPDscUpdateCalled | Should Be $true
            }
        }

        Context -Name 'When enabling Incoming Email, but not specifying required ServerDisplayAddress parameter' -Fixture {
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

            $mock = @{
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

        Context -Name 'When enabling Incoming Email, but not specifying required UseAutomaticSettings parameter' -Fixture {
            $testParams = @{
                IsSingleInstance               = 'Yes'
                Ensure                         = 'Present'
                #UseAutomaticSettings           = $false
                UseDirectoryManagementService  = 'Remote'
                RemoteDirectoryManagementURL   = 'http://server:adminport/_vti_bin/SharepointEmailWS.asmx'
                DLsRequireAuthenticatedSenders = $false
                DistributionGroupsEnabled      = $true
                ServerDisplayAddress           = "contoso.com"
                DropFolder                     = '\\MailServer\SharedFolder'
            }

            $mock = @{
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

            It "Should return current values for the Get method" {
                $result = Get-TargetResource @testParams
                $result.Ensure | Should Be $testParams.Ensure
                $result.UseAutomaticSettings | Should Be $mock.UseAutomaticSettings
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
                { Set-TargetResource @testParams } | Should throw "UseAutomaticSettings parameter must be specified when enabling incoming email."
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

            $mock = @{
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

            $mock = @{
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

            $mock = @{
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
