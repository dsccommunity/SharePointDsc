[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4693.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 

$ModuleName = "MSFT_xSPSearchContentSource"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPSearchContentSource" {
    InModuleScope $ModuleName {
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\xSharePoint")
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 

        Mock Invoke-xSharePointCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        Mock Start-Sleep {}
        
        Context "A SharePoint content source doesn't exist but should" {
            $testParams = @{
                Name = "Example content source"
                ServiceAppName = "Search Service Application"
                ContentSourceType = "SharePoint"
                Addresses = @("http://site.contoso.com")
                CrawlSetting = "CrawlEverything"
                Ensure = "Present"
            }
            
            It "should return absent from the get method" {
                $result = Get-TargetResource @testParams
                $result.Ensure | Should Be "Absent"
            }
            
            It "should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
            
            It "should create the content source in the set method" {
                Set-TargetResource @testParams
                
                #TODO: Check mock calls
            }
        }
        
        Context "A SharePoint content source does exist and should" {
            
            It "should return present from the get method" {
                
            }
            
            It "should return true from the test method" {
                
            }
        }
        
        Context "A SharePoint content source does exist and shouldn't" {
            
            It "should return present from the get method" {
                
            }
            
            It "should return false from the test method" {
                
            }
            
            It "should remove the content source in the set method" {
                
            }
        }
        
        Context "A SharePoint content source doesn't exist and shouldn't" {
            
            It "should return absent from the get method" {
                
            }
            
            It "should return true from the test method" {
                
            }
        }
        
        Context "A SharePoint source that uses continuous crawl has incorrect settings applied" {
            
            It "should return false from the test method" {
                
            }
            
            It "should disable continuous crawl and then re-enable it when updating the content source" {
                
            }
        }
        
        Context "A website content source doesn't exist but should" {
            
            It "should return absent from the get method" {
                
            }
            
            It "should return false from the test method" {
                
            }
            
            It "should create the content source in the set method" {
                
            }
        }
        
        Context "A website content source does exist and should" {
            
            It "should return present from the get method" {
                
            }
            
            It "should return true from the test method" {
                
            }
        }
        
        Context "A website content source does exist and shouldn't" {
            
            It "should return present from the get method" {
                
            }
            
            It "should return false from the test method" {
                
            }
            
            It "should remove the content source in the set method" {
                
            }
        }
        
        Context "A website content source doesn't exist and shouldn't" {
            
            It "should return absent from the get method" {
                
            }
            
            It "should return true from the test method" {
                
            }
        }
        
        Context "A website content source has incorrect crawl depth settings applied" {
            
            It "should return false from the test method" {
                
            }
            
            It "should update the settings in the set method" {
                
            }
        }
        
        Context "A file share content source doesn't exist but should" {
            
            It "should return absent from the get method" {
                
            }
            
            It "should return false from the test method" {
                
            }
            
            It "should create the content source in the set method" {
                
            }
        }
        
        Context "A file share content source does exist and should" {
            
            It "should return present from the get method" {
                
            }
            
            It "should return true from the test method" {
                
            }
        }
        
        Context "A file share content source does exist and shouldn't" {
            
            It "should return present from the get method" {
                
            }
            
            It "should return false from the test method" {
                
            }
            
            It "should remove the content source in the set method" {
                
            }
        }
        
        Context "A file share content source doesn't exist and shouldn't" {
            
            It "should return absent from the get method" {
                
            }
            
            It "should return true from the test method" {
                
            }
        }
        
        Context "A file share content source has incorrect crawl depth settings applied" {
            
            It "should return false from the test method" {
                
            }
            
            It "should update the settings in the set method" {
                
            }
        }
        
        Context "A content source has a full schedule that does not match the desired schedule" {
            
            It "should return false from the test method" {
                
            }
            
            It "should update the schedule in the set method" {
                
            }
        }
        
        Context "A content source has a full schedule that does match the desired schedule" {
            
            It "should return true from the test method" {
                
            }
        }
        
        Context "A content source has a incremental schedule that does not match the desired schedule" {
            
            It "should return false from the test method" {
                
            }
            
            It "should update the schedule in the set method" {
                
            }
        }
        
        Context "A content source has a incremental schedule that does match the desired schedule" {
            
            It "should return true from the test method" {
                
            }
        }
    }
}