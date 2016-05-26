[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4693.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 

$ModuleName = "MSFT_SPIrmSettings"
Import-Module (Join-Path $RepoRoot "Modules\SharePointDSC\DSCResources\$ModuleName\$ModuleName.psm1") -Force


Describe "SPIrmSettings - SharePoint Build $((Get-Item $SharePointCmdletModule).Directory.BaseName)" {
    InModuleScope $ModuleName {
        
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\SharePointDSC")
        
        Mock Invoke-SPDSCCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue
               
                
        Context "The server is not part of SharePoint farm" {
            Mock Get-SPFarm { throw "Unable to detect local farm" }

            $testParams = @{
              Ensure = "Present"
              RMSserver = "https://myRMSserver.local"
            }
        
            It "return null from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "throws an exception in the set method to say there is no local farm" {
                { Set-TargetResource @testParams } | Should throw "No local SharePoint farm was detected"
            }
        }
        

        Context "IRM settings match desired settings" {
            
            Mock Get-SPDSCContentService {
            $returnVal = @{
                 IrmSettings = @{
                    IrmRMSEnabled = $true 
                    IrmRMSUseAD = $false
                    IrmRMSCertServer = "https://myRMSserver.local"
                }
            } 
            $returnVal = $returnVal | Add-Member ScriptMethod Update { $Global:SPDSCIRMUpdated = $true } -PassThru
            return $returnVal
            }
            
            Mock Get-SPFarm { return @{} }
            
            $TestParams = @{
                    Ensure = "Present"
                    RMSserver = "https://myRMSserver.local"
            }
            
            It "Get returns current settings" {
                 (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }
            
            It "Test returns True" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
        
        
         Context "IRM settings do not match desired settings" {
            
            Mock Get-SPDSCContentService {
            $returnVal = @{
                 IrmSettings = @{
                    IrmRMSEnabled = $false  
                    IrmRMSUseAD = $false
                    IrmRMSCertServer = $null 
                   }
            } 
            $returnVal = $returnVal | Add-Member ScriptMethod Update { $Global:SPDSCIRMUpdated = $true } -PassThru
            return $returnVal
            }
            
            Mock Get-SPFarm { return @{} }
            
            $TestParams = @{
                    Ensure = "Present"
                    RMSserver = "https://myRMSserver.local"
            }
            
            It "Get returns current settings" {
                 (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }
            
            It "Test returns False" {
                Test-TargetResource @testParams | Should Be $false 
            }
            
            $Global:SPDSCIRMUpdated =
            It "Set applies desired settings" {
                Set-TargetResource @testParams
                $Global:SPDSCIRMUpdated | Should Be $true
            }
            
            It "UseAD and RMSserver both supplied (can only use one), should throw" {
                $TestParams.Add("UseADRMS",$true)
                { Set-TargetResource @testParams }| Should Throw 
            }
        }
        
        
        
        
        
        
    }
}
