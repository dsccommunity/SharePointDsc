[CmdletBinding()] 
param( 
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve) 
) 

$ErrorActionPreference = 'stop' 
Set-StrictMode -Version latest 

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path 
$Global:CurrentSharePointStubModule = $SharePointCmdletModule  

$ModuleName = "MSFT_SPWordAutomationServiceApp" 
Import-Module (Join-Path $RepoRoot "Modules\SharePointDSC\DSCResources\$ModuleName\$ModuleName.psm1") -Force

Describe "SPWordAutomationServiceApp - SharePoint Build $((Get-Item $SharePointCmdletModule).Directory.BaseName)" { 
    InModuleScope $ModuleName { 
        $testParams = @{ 
            Name = "Word Automation Service Application" 
            Ensure = "Present"
            ApplicationPool = "SharePoint Web Services"
            DatabaseName = "WordAutomation_DB"
            DatabaseServer = "SQLServer"
            SupportedFileFormats = "docx", "doc", "mht", "rtf", "xml"
            DisableEmbeddedFonts = $false
            MaximumMemoryUsage = 100
            RecycleThreshold = 100
            DisableBinaryFileScan = $false
            ConversionProcesses = 8
            JobConversionFrequency = 15
            NumberOfConversionsPerProcess = 12
            TimeBeforeConversionIsMonitored = 5
            MaximumConversionAttempts = 2
            MaximumSyncConversionRequests = 25 
            KeepAliveTimeout = 30
            MaximumConversionTime = 300
        } 
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\SharePointDSC") 

        Mock Invoke-SPDSCCommand {  
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope 
        } 
         
        Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force -ErrorAction SilentlyContinue 
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 

        Context "When no service applications exist in the current farm and Ensure is set to Present" { 

            Mock Get-SPServiceApplication { return $null } 
            Mock New-SPWordConversionServiceApplication {
                $returnval = @(@{
                    WordServiceFormats = @{
                        OpenXmlDocument = $false
                        Word972003Document = $true
                        RichTextFormat = $true
                        WebPage = $true
                        Word2003Xml = $true
                    }
                    DisableEmbeddedFonts = $false
                    MaximumMemoryUsage = 100
                    RecycleProcessThreshold = 100
                    DisableBinaryFileScan = $false
                    TotalActiveProcesses = 8
                    TimerJobFrequency = 15
                    ConversionsPerInstance = 12
                    ConversionTimeout = 5
                    MaximumConversionAttempts = 2
                    MaximumSyncConversionRequests = 25
                    KeepAliveTimeout = 30
                    MaximumConversionTime = 300
                })
                $returnVal = $returnVal | Add-Member ScriptMethod Update { $Global:SPDSCSiteUseUpdated = $true } -PassThru
                return $returnval
            } 
            Mock Get-SPServiceApplicationPool {
                return @(@{ 
                    Name = $testParams.ApplicationPool
                }) 
            }

            Mock Get-SPTimerJob {
                $returnval = @(@{ Name = "Just a name" })
                return ,$returnval
            }
            Mock Set-SPTimerJob {}

            It "returns null from the Get method" { 
                Get-TargetResource @testParams | Should BeNullOrEmpty 
                Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParams.Name }  
            } 

            It "returns false when the Test method is called" { 
                Test-TargetResource @testParams | Should Be $false 
            } 

            $Global:SPDSCSiteUseUpdated = $false
            It "creates a new service application in the set method" { 
                Set-TargetResource @testParams 
                Assert-MockCalled New-SPWordConversionServiceApplication  
                $Global:SPDSCSiteUseUpdated | Should Be $true
            } 
        } 

        Context "When no service applications exist in the current farm and Ensure is set to Present, but the Application Pool does not exist" { 
            Mock Get-SPServiceApplication { return $null } 
            Mock Get-SPServiceApplicationPool { return $null }

            It "fails to create a new service application in the set method because the specified application pool is missing" { 
                { Set-TargetResource @testParams } | Should throw "Specified application pool does not exist"
            } 
        }

        Context "When service applications exist in the current farm but the specific word automation app does not" { 

            Mock Get-SPServiceApplication { return @(@{ 
                TypeName = "Some other service app type" 
            }) } 

            It "returns null from the Get method" { 
                Get-TargetResource @testParams | Should BeNullOrEmpty 
                Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParams.Name }  
            } 
        } 

        Context "When a service application exists and is configured correctly" { 
            Mock Get-SPServiceApplication {  
                return @(@{ 
                    TypeName = "Word Automation Services" 
                    DisplayName = $testParams.Name 
                    ApplicationPool = @{ Name = $testParams.ApplicationPool } 
                    Database = @{
                            Name = $testParams.DatabaseName
                            Server = @{ Name = $testParams.DatabaseServer }
                    }
                    WordServiceFormats = @{
                        OpenXmlDocument = $true
                        Word972003Document = $true
                        RichTextFormat = $true
                        WebPage = $true
                        Word2003Xml = $true
                    }
                    DisableEmbeddedFonts = $false
                    MaximumMemoryUsage = 100
                    RecycleProcessThreshold = 100
                    DisableBinaryFileScan = $false
                    TotalActiveProcesses = 8
                    TimerJobFrequency = @{ TotalMinutes = 15 }
                    ConversionsPerInstance = 12
                    ConversionTimeout = @{ TotalMinutes = 5 }
                    MaximumConversionAttempts = 2
                    MaximumSyncConversionRequests = 25
                    KeepAliveTimeout = @{ TotalSeconds = 30 }
                    MaximumConversionTime = @{ TotalSeconds = 300 }
                }) 
            } 

            It "returns values from the get method" { 
                Get-TargetResource @testParams | Should Not BeNullOrEmpty 
            } 

            It "returns true when the Test method is called" { 
                Test-TargetResource @testParams | Should Be $true 
            } 
        } 

        Context "When a service application exists and incorrect application pool is configured" { 
            Mock Get-SPServiceApplication {  
                $returnval = @(@{ 
                    TypeName = "Word Automation Services" 
                    DisplayName = $testParams.Name 
                    ApplicationPool = @{ Name = "Wrong App Pool Name" } 
                    WordServiceFormats = @{
                        OpenXmlDocument = $false
                        Word972003Document = $true
                        RichTextFormat = $true
                        WebPage = $true
                        Word2003Xml = $true
                    }
                    DisableEmbeddedFonts = $false
                    MaximumMemoryUsage = 100
                    RecycleProcessThreshold = 100
                    DisableBinaryFileScan = $false
                    TotalActiveProcesses = 8
                    TimerJobFrequency = 15
                    ConversionsPerInstance = 12
                    ConversionTimeout = 5
                    MaximumConversionAttempts = 2
                    MaximumSyncConversionRequests = 25
                    KeepAliveTimeout = 30
                    MaximumConversionTime = 300
                }) 
                $returnVal = $returnVal | Add-Member ScriptMethod Update { $Global:SPDSCSiteUseUpdated = $true } -PassThru
                return $returnval
            } 

            Mock Get-SPServiceApplicationPool { return @{ Name = $testParams.ApplicationPool } } 
            Mock Set-SPWordConversionServiceApplication {}

            Mock Get-SPTimerJob {
                $returnval = @(@{ Name = "Just a name" })
                return ,$returnval
            }
            Mock Set-SPTimerJob {}

            It "returns false when the Test method is called" { 
                Test-TargetResource @testParams | Should Be $false 
            } 

            $Global:SPDSCSiteUseUpdated = $false
            It "calls the update service app cmdlet from the set method" { 
                Set-TargetResource @testParams 

                Assert-MockCalled Get-SPServiceApplicationPool 
                Assert-MockCalled Set-SPWordConversionServiceApplication 
                $Global:SPDSCSiteUseUpdated | Should Be $true
            } 
        } 

        Context "When a service application exists and incorrect settings are configured" { 
            Mock Get-SPServiceApplication {  
                $returnval = @(@{
                    TypeName = "Word Automation Services" 
                    DisplayName = $testParams.Name 
                    ApplicationPool = @{ Name = $testParams.ApplicationPool } 
                    WordServiceFormats = @{
                        OpenXmlDocument = $false
                        Word972003Document = $true
                        RichTextFormat = $true
                        WebPage = $true
                        Word2003Xml = $true
                    }
                    DisableEmbeddedFonts = $false
                    MaximumMemoryUsage = 100
                    RecycleProcessThreshold = 100
                    DisableBinaryFileScan = $false
                    TotalActiveProcesses = 8
                    TimerJobFrequency = 15
                    ConversionsPerInstance = 12
                    ConversionTimeout = 5
                    MaximumConversionAttempts = 2
                    MaximumSyncConversionRequests = 25
                    KeepAliveTimeout = 30
                    MaximumConversionTime = 300
                })
                $returnVal = $returnVal | Add-Member ScriptMethod Update { $Global:SPDSCSiteUseUpdated = $true } -PassThru
                return $returnval
            } 

            Mock Get-SPServiceApplicationPool { return @{ Name = $testParams.ApplicationPool } } 
            Mock Set-SPWordConversionServiceApplication {}

            Mock Get-SPTimerJob {
                $returnval = @(@{ Name = "Just a name" })
                return ,$returnval
            }
            Mock Set-SPTimerJob {}

            It "returns false when the Test method is called" { 
                Test-TargetResource @testParams | Should Be $false 
            } 

            $Global:SPDSCSiteUseUpdated = $false
            It "calls the update service app cmdlet from the set method" { 
                Set-TargetResource @testParams 
                Assert-MockCalled Get-SPServiceApplication
                $Global:SPDSCSiteUseUpdated | Should Be $true
            } 
        }

        Context "When no service application exists and Ensure is set to Absent" {
            $testParams = @{ 
                Name = "Word Automation Service Application" 
                Ensure = "Absent"
            }

            Mock Get-SPServiceApplication { return $null } 

            It "returns values from the get method" { 
                Get-TargetResource @testParams | Should Not BeNullOrEmpty 
                Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParams.Name }  
            } 

            It "returns true when the Test method is called" { 
                Test-TargetResource @testParams | Should Be $true 
            } 
        } 

        Context "When a service application exists and Ensure is set to Absent" {
            $testParams = @{ 
                Name = "Word Automation Service Application" 
                Ensure = "Absent"
            }

            Mock Get-SPServiceApplication { 
                return @(@{ 
                    TypeName = "Word Automation Services" 
                    DisplayName = $testParams.Name 
                }) 
            } 
            Mock Remove-SPServiceApplication { } 

            It "should return null from the get method" { 
                Get-TargetResource @testParams | Should BeNullOrEmpty 
                Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParams.Name }  
            } 

            It "should return false when the Test method is called" { 
                Test-TargetResource @testParams | Should Be $false 
            }

            It "should call the update service app cmdlet from the set method" { 
                Set-TargetResource @testParams 
                Assert-MockCalled Remove-SPServiceApplication 
            }
        }

        Context "When Ensure is set to Absent, but another parameter is also used" {
            $testParams = @{
                Name = "Word Automation Service Application" 
                Ensure = "Absent"
                ApplicationPool = "SharePoint Web Services"
            } 

            It "should return null from the get method" {
                { Get-TargetResource @testParams } | Should throw "You cannot use any of the parameters when Ensure is specified as Absent"
            }

            It "should return false from the test method" {
                { Test-TargetResource @testParams } | Should throw "You cannot use any of the parameters when Ensure is specified as Absent"
            }

            It "should throw an exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "You cannot use any of the parameters when Ensure is specified as Absent"
            }
        } 

        Context "When Ensure is set to Present, but the Application Pool or Database parameters are missing" {
            $testParams = @{
                Name = "Word Automation Service Application" 
                Ensure = "Present"
                ApplicationPool = "SharePoint Web Services"
            } 

            It "should return null from the get method" {
                { Get-TargetResource @testParams } | Should throw "An Application Pool and Database Name are required to configure the Word Automation Service Application"
            }

            It "should return false from the test method" {
                { Test-TargetResource @testParams } | Should throw "An Application Pool and Database Name are required to configure the Word Automation Service Application"
            }

            It "should throw an exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "An Application Pool and Database Name are required to configure the Word Automation Service Application"
            }
        } 

    } 
} 
