[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 

$ModuleName = "MSFT_SPServiceAppProxyGroup"
Import-Module (Join-Path $RepoRoot "Modules\SharePointDSC\DSCResources\$ModuleName\$ModuleName.psm1") -Force

Describe "SPServiceAppProxyGroup - SharePoint Build $((Get-Item $SharePointCmdletModule).Directory.BaseName)" {
    InModuleScope $ModuleName {
               
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\SharePointDSC")

        
        Mock Invoke-SPDSCCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force -ErrorAction SilentlyContinue
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue
        
        $ListofAllServiceAppProxies = @(
            "Web 1 User Profile Service Application",
            "Web 1 MMS Service Application",
            "State Service Application"
            "Web 2 User Profile Service Application"
        )
        
                
        
        Mock Add-SPServiceApplicationProxyGroupMember {}
        Mock Remove-SPServiceApplicationProxyGroupMember {}
        Mock Get-SPServiceApplicationProxy { $ProxiesToReturn = @()
                               foreach ($ServiceAppProxy in $ListofAllServiceAppProxies ){ 
                                    $ProxiesToReturn +=  @{ DisplayName = $ServiceAppProxy }}
                                    return $ProxiesToReturn  
                               }
            
        Mock New-SPServiceApplicationProxyGroup { return @{ Name = $TestParams.Name} }

        Context "ServiceAppProxies and ServiceAppProxiesToInclude parameters used simultaniously" {
            $testParams = @{
                Name              = "Shared Services"
                Ensure            = "Present"
                ServiceAppProxies = "Web 1 User Profile Service Application","Web 1 MMS Service Application","State Service Application"
                ServiceAppProxiesToInclude = "Web 2 User Profile Service Application"
            }

            It "return null from the get method" {
                Get-TargetResource @testParams | Should Be $null
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "should throw an exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "Cannot use the ServiceAppProxies parameter together with the ServiceAppProxiesToInclude or ServiceAppProxiesToExclude parameters"
            }
        }

        Context "None of the ServiceAppProxies, ServiceAppProxiesToInclude and ServiceAppProxiesToExclude parameters are used" {
            $testParams = @{
                Name              = "My Proxy Group"
                Ensure            = "Present"
            }

            It "return null from the get method" {
                Get-TargetResource @testParams | Should Be $null
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "should throw an exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "At least one of the following parameters must be specified: ServiceAppProxies, ServiceAppProxiesToInclude,ServiceAppProxiesToExclude"
            }
        }

        Context "The Service Application Proxy Group does not exist and should" {
            $testParams = @{
                Name              = "Shared Services"
                Ensure            = "Present"
                ServiceAppProxies = @("State Service Application","Web 1 User Profile Service Application")
            }
            
            Mock Get-SPServiceApplicationProxyGroup { return $null }
            
            It "returns ensure = absent  from the get method" {
                (Get-TargetResource @testParams).Ensure | Should be 'Absent' 
            }
            
            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false 
            }
            
            It "creates the Service Application Proxy Group with the set method" {
                Set-TargetResource @testParams 
                Assert-MockCalled New-SPServiceApplicationProxyGroup
            }
        }
        
        Context "The ServiceApplication Proxy Group does not exist, and should not" {
            $testParams = @{
                Name              = "Shared Services"
                Ensure            = "Absent"
            }
            
            Mock Get-SPServiceApplicationProxyGroup { return $null }
            
            It "returns ensure = absent  from the get method" {
                (Get-TargetResource @testParams).Ensure | Should be 'Absent' 
            }
            
            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true 
            }
        
        }
        
        Context "The Service Application Proxy Group exists and should, ServiceAppProxies match" {
            $testParams = @{
                Name              = "Shared Services"
                Ensure            = "Present"
                ServiceAppProxies = @("State Service Application","Web 1 User Profile Service Application")
            }
            
            Mock Get-SPServiceApplicationProxyGroup { 
                            $ProxiesToReturn = @()
                            foreach ($ServiceAppProxy in $TestParams.ServiceAppProxies ){ 
                                $ProxiesToReturn +=  @{ Name = $ServiceAppProxy }
                            }
                            return @{ 
                                Name = $testParams.Name
                                Proxies = $ProxiesToReturn
                            } 
                        }
            
            It "returns ensure = present  from the get method" {
                (Get-TargetResource @testParams).Ensure | Should be 'Present' 
            }
            
            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true 
            }
        }
 
        Context "The Service Application Proxy Group exists and should, ServiceAppProxies do not match" {
            $testParams = @{
                Name              = "Shared Services"
                Ensure            = "Present"
                ServiceAppProxies = @("State Service Application","Web 1 User Profile Service Application")
            }
            
            $ServiceAppProxiesConfigured = @("State Service Application","Web 2 User Profile Service Application")
            
            Mock Get-SPServiceApplicationProxyGroup { 
                            $ProxiesToReturn = @()
                            foreach ($ServiceAppProxy in $ServiceAppProxiesConfigured ){ 
                                $ProxiesToReturn +=  @{ Name = $ServiceAppProxy }
                            }
                            return @{ 
                                Name = $testParams.Name
                                Proxies = $ProxiesToReturn
                            } 
                        }
            
            It "returns ensure = present  from the get method" {
                (Get-TargetResource @testParams).Ensure | Should be 'Present' 
            }
            
            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false 
            }
            
            It "Set method Adds the missing Service Proxy" {
                Set-TargetResource @testParams
                Assert-MockCalled Add-SPServiceApplicationProxyGroupMember -Exactly 1
            }
            
            It "Set method Removes the extra Service Proxy" {
                Assert-MockCalled Remove-SPServiceApplicationProxyGroupMember -Exactly 1
            }
        }
        
        Context "The Service Application Proxy Group exists and should, ServiceAppProxiesToInclude matches" {
            $testParams = @{
                Name              = "Shared Services"
                Ensure            = "Present"
                ServiceAppProxiesToInclude = @("State Service Application","Web 1 User Profile Service Application")
            }
            
            $ServiceAppProxiesConfigured = @("State Service Application","Web 1 User Profile Service Application","Web 1 MMS Service Application")
            
            Mock Get-SPServiceApplicationProxyGroup { 
                            $ProxiesToReturn = @()
                            foreach ($ServiceAppProxy in $ServiceAppProxiesConfigured ){ 
                                $ProxiesToReturn +=  @{ Name = $ServiceAppProxy }
                            }
                            return @{ 
                                Name = $testParams.Name
                                Proxies = $ProxiesToReturn
                            } 
                        }
            
            It "returns ensure = present  from the get method" {
                (Get-TargetResource @testParams).Ensure | Should be 'Present' 
            }
            
            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true 
            }
            
        }
        
        Context "The Service Application Proxy Group exists and should, ServiceAppProxiesToInclude does not match" {
            $testParams = @{
                Name              = "Shared Services"
                Ensure            = "Present"
                ServiceAppProxiesToInclude = @("State Service Application","Web 1 User Profile Service Application")
            }
            
            $ServiceAppProxiesConfigured = @("State Service Application","Web 1 MMS Service Application")
            
            Mock Get-SPServiceApplicationProxyGroup { 
                            $ProxiesToReturn = @()
                            foreach ($ServiceAppProxy in $ServiceAppProxiesConfigured ){ 
                                $ProxiesToReturn +=  @{ Name = $ServiceAppProxy }
                            }
                            return @{ 
                                Name = $testParams.Name
                                Proxies = $ProxiesToReturn
                            } 
                        }
            
            It "returns ensure = present  from the get method" {
                (Get-TargetResource @testParams).Ensure | Should be 'Present' 
            }
            
            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false 
            }
            
            It "Set method Adds the missing Service Proxy" {
                Set-TargetResource @testParams
                Assert-MockCalled Add-SPServiceApplicationProxyGroupMember -Exactly 1
            }
            
            It "Set method does not remove extra Service Proxies" {
                Assert-MockCalled Remove-SPServiceApplicationProxyGroupMember -Exactly 0
            }
            
        }
        
        Context "The Service Application Proxy Group exists and should, ServiceAppProxiesToExclude matches" {
            $testParams = @{
                Name              = "Shared Services"
                Ensure            = "Present"
                ServiceAppProxiesToExclude = @("Web 1 User Profile Service Application")
            }
            
            $ServiceAppProxiesConfigured = @("State Service Application","Web 1 MMS Service Application")
            
            Mock Get-SPServiceApplicationProxyGroup { 
                            $ProxiesToReturn = @()
                            foreach ($ServiceAppProxy in $ServiceAppProxiesConfigured ){ 
                                $ProxiesToReturn +=  @{ Name = $ServiceAppProxy }
                            }
                            return @{ 
                                Name = $testParams.Name
                                Proxies = $ProxiesToReturn
                            } 
                        }
            
            It "returns ensure = present  from the get method" {
                (Get-TargetResource @testParams).Ensure | Should be 'Present' 
            }
            
            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
            
        }
        
        Context "The Service Application Proxy Group exists and should, ServiceAppProxiesToExclude does not match" {
            $testParams = @{
                Name              = "Shared Services"
                Ensure            = "Present"
                ServiceAppProxiesToExclude = @("Web 1 User Profile Service Application","Web 2 User Profile Service Application")
            }
            
            $ServiceAppProxiesConfigured = @("State Service Application","Web 1 MMS Service Application","Web 1 User Profile Service Application")
            
            Mock Get-SPServiceApplicationProxyGroup { 
                            $ProxiesToReturn = @()
                            foreach ($ServiceAppProxy in $ServiceAppProxiesConfigured ){ 
                                $ProxiesToReturn +=  @{ Name = $ServiceAppProxy }
                            }
                            return @{ 
                                Name = $testParams.Name
                                Proxies = $ProxiesToReturn
                            } 
                        }
            
            It "returns ensure = present  from the get method" {
                (Get-TargetResource @testParams).Ensure | Should be 'Present' 
            }
            
            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
            
            It "Set method removes the Service Proxy" {
                Set-TargetResource @testParams
                Assert-MockCalled Remove-SPServiceApplicationProxyGroupMember -Exactly 1
            }
            
            It "Set method does not Add extra Service Proxies" {
                Assert-MockCalled Add-SPServiceApplicationProxyGroupMember -Exactly 0
            }
            
        }
        
        Context "Specified service application does not exist, ServiceAppProxies specified" {
            $testParams = @{
                Name              = "Shared Services"
                Ensure            = "Present"
                ServiceAppProxies = @("No Such Service Application","Web 1 User Profile Service Application")
            }
            
            Mock Get-SPServiceApplicationProxyGroup { 
                            $ProxiesToReturn = @()
                            foreach ($ServiceAppProxy in "Web 1 User Profile Service Application" ){ 
                                $ProxiesToReturn +=  @{ Name = $ServiceAppProxy }
                            }
                            return @{ 
                                Name = $testParams.Name
                                Proxies = $ProxiesToReturn
                            } 
                        }
            
            It "returns ensure = present  from the get method" {
                (Get-TargetResource @testParams).Ensure | Should be 'Present' 
            }
            
            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false 
            }
            
            It "throws an error from the set method" {
               { Set-TargetResource @testParams }| Should throw "Invalid Service Application Proxy No Such Service Application"
            }       
        }
        
        Context "Specified service application does not exist, ServiceAppProxiesToInclude specified" {
            $testParams = @{
                Name              = "Shared Services"
                Ensure            = "Present"
                ServiceAppProxiesToInclude = @("No Such Service Application","Web 1 User Profile Service Application")
            }
            
            Mock Get-SPServiceApplicationProxyGroup { 
                            $ProxiesToReturn = @()
                            foreach ($ServiceAppProxy in "Web 1 User Profile Service Application" ){ 
                                $ProxiesToReturn +=  @{ Name = $ServiceAppProxy }
                            }
                            return @{ 
                                Name = $testParams.Name
                                Proxies = $ProxiesToReturn
                            } 
                        }
            
            It "returns ensure = present  from the get method" {
                (Get-TargetResource @testParams).Ensure | Should be 'Present' 
            }
            
            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false 
            }
            
            It "throws an error from the set method" {
               { Set-TargetResource @testParams }| Should throw "Invalid Service Application Proxy No Such Service Application"
            }       
        }
        


    }
}
