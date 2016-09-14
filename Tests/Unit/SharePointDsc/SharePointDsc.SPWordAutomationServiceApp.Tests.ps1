[CmdletBinding()] 
param( 
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve) 
) 

$ErrorActionPreference = 'stop' 
Set-StrictMode -Version latest 

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..\..).Path 
$Global:CurrentSharePointStubModule = $SharePointCmdletModule  

$ModuleName = "MSFT_SPWordAutomationServiceApp" 
Import-Module (Join-Path $RepoRoot "Modules\SharePointDsc\DSCResources\$ModuleName\$ModuleName.psm1") -Force

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
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..\..).Path) "Modules\SharePointDsc") 

        Mock Invoke-SPDSCCommand {  
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope 
        } 
         
        Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force -ErrorAction SilentlyContinue 
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 

        Context -Name "When no service applications exist in the current farm and Ensure is set to Present" { 

            Mock -CommandName Get-SPServiceApplication -MockWith { return $null } 
            Mock -CommandName New-SPWordConversionServiceApplication {
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
                $returnVal = $returnVal | Add-Member -MemberType ScriptMethod -Name Update -Value { $Global:SPDscSiteUseUpdated = $true } -PassThru
                return $returnval
            } 
            Mock -CommandName Get-SPServiceApplicationPool {
                return @(@{ 
                    Name = $testParams.ApplicationPool
                }) 
            }

            Mock -CommandName Get-SPTimerJob {
                $returnval = @(@{ Name = "Just a name" })
                return ,$returnval
            }
            Mock -CommandName Set-SPTimerJob {}

            It "Should return null from the Get method" { 
                Get-TargetResource @testParams | Should BeNullOrEmpty 
                Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParams.Name }  
            } 

            It "Should return false when the Test method is called" { 
                Test-TargetResource @testParams | Should Be $false 
            } 

            $Global:SPDscSiteUseUpdated = $false
            It "Should create a new service application in the set method" { 
                Set-TargetResource @testParams 
                Assert-MockCalled New-SPWordConversionServiceApplication  
                $Global:SPDscSiteUseUpdated | Should Be $true
            } 
        } 

        Context -Name "When no service applications exist in the current farm and Ensure is set to Present, but the Application Pool does not exist" { 
            Mock -CommandName Get-SPServiceApplication -MockWith { return $null } 
            Mock -CommandName Get-SPServiceApplicationPool { return $null }

            It "fails to create a new service application in the set method because the specified application pool is missing" { 
                { Set-TargetResource @testParams } | Should throw "Specified application pool does not exist"
            } 
        }

        Context -Name "When service applications exist in the current farm but the specific word automation app does not" { 

            Mock -CommandName Get-SPServiceApplication -MockWith { return @(@{ 
                TypeName = "Some other service app type" 
            }) } 

            It "Should return null from the Get method" { 
                Get-TargetResource @testParams | Should BeNullOrEmpty 
                Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParams.Name }  
            } 
        } 

        Context -Name "When a service application exists and is configured correctly" { 
            Mock -CommandName Get-SPServiceApplication -MockWith {  
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

            It "Should return values from the get method" { 
                Get-TargetResource @testParams | Should Not BeNullOrEmpty 
            } 

            It "Should return true when the Test method is called" { 
                Test-TargetResource @testParams | Should Be $true 
            } 
        } 

        Context -Name "When a service application exists and incorrect application pool is configured" { 
            Mock -CommandName Get-SPServiceApplication -MockWith {  
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
                $returnVal = $returnVal | Add-Member -MemberType ScriptMethod -Name Update -Value { $Global:SPDscSiteUseUpdated = $true } -PassThru
                return $returnval
            } 

            Mock -CommandName Get-SPServiceApplicationPool { return @{ Name = $testParams.ApplicationPool } } 
            Mock -CommandName Set-SPWordConversionServiceApplication {}

            Mock -CommandName Get-SPTimerJob {
                $returnval = @(@{ Name = "Just a name" })
                return ,$returnval
            }
            Mock -CommandName Set-SPTimerJob {}

            It "Should return false when the Test method is called" { 
                Test-TargetResource @testParams | Should Be $false 
            } 

            $Global:SPDscSiteUseUpdated = $false
            It "Should call the update service app cmdlet from the set method" { 
                Set-TargetResource @testParams 

                Assert-MockCalled Get-SPServiceApplicationPool 
                Assert-MockCalled Set-SPWordConversionServiceApplication 
                $Global:SPDscSiteUseUpdated | Should Be $true
            } 
        } 

        Context -Name "When a service application exists and incorrect settings are configured" { 
            Mock -CommandName Get-SPServiceApplication -MockWith {  
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
                $returnVal = $returnVal | Add-Member -MemberType ScriptMethod -Name Update -Value { $Global:SPDscSiteUseUpdated = $true } -PassThru
                return $returnval
            } 

            Mock -CommandName Get-SPServiceApplicationPool { return @{ Name = $testParams.ApplicationPool } } 
            Mock -CommandName Set-SPWordConversionServiceApplication {}

            Mock -CommandName Get-SPTimerJob {
                $returnval = @(@{ Name = "Just a name" })
                return ,$returnval
            }
            Mock -CommandName Set-SPTimerJob {}

            It "Should return false when the Test method is called" { 
                Test-TargetResource @testParams | Should Be $false 
            } 

            $Global:SPDscSiteUseUpdated = $false
            It "Should call the update service app cmdlet from the set method" { 
                Set-TargetResource @testParams 
                Assert-MockCalled Get-SPServiceApplication
                $Global:SPDscSiteUseUpdated | Should Be $true
            } 
        }

        Context -Name "When no service application exists and Ensure is set to Absent" {
            $testParams = @{ 
                Name = "Word Automation Service Application" 
                Ensure = "Absent"
            }

            Mock -CommandName Get-SPServiceApplication -MockWith { return $null } 

            It "Should return values from the get method" { 
                Get-TargetResource @testParams | Should Not BeNullOrEmpty 
                Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParams.Name }  
            } 

            It "Should return true when the Test method is called" { 
                Test-TargetResource @testParams | Should Be $true 
            } 
        } 

        Context -Name "When a service application exists and Ensure is set to Absent" {
            $testParams = @{ 
                Name = "Word Automation Service Application" 
                Ensure = "Absent"
            }

            Mock -CommandName Get-SPServiceApplication -MockWith { 
                return @(@{ 
                    TypeName = "Word Automation Services" 
                    DisplayName = $testParams.Name 
                }) 
            } 
            Mock -CommandName Remove-SPServiceApplication { } 

            It "Should return null from the get method" { 
                Get-TargetResource @testParams | Should BeNullOrEmpty 
                Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParams.Name }  
            } 

            It "Should return false when the Test method is called" { 
                Test-TargetResource @testParams | Should Be $false 
            }

            It "Should call the update service app cmdlet from the set method" { 
                Set-TargetResource @testParams 
                Assert-MockCalled Remove-SPServiceApplication 
            }
        }

        Context -Name "When Ensure is set to Absent, but another parameter is also used" {
            $testParams = @{
                Name = "Word Automation Service Application" 
                Ensure = "Absent"
                ApplicationPool = "SharePoint Web Services"
            } 

            It "Should return null from the get method" {
                { Get-TargetResource @testParams } | Should throw "You cannot use any of the parameters when Ensure is specified as Absent"
            }

            It "Should return false from the test method" {
                { Test-TargetResource @testParams } | Should throw "You cannot use any of the parameters when Ensure is specified as Absent"
            }

            It "Should throw an exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "You cannot use any of the parameters when Ensure is specified as Absent"
            }
        } 

        Context -Name "When Ensure is set to Present, but the Application Pool or Database parameters are missing" {
            $testParams = @{
                Name = "Word Automation Service Application" 
                Ensure = "Present"
                ApplicationPool = "SharePoint Web Services"
            } 

            It "Should return null from the get method" {
                { Get-TargetResource @testParams } | Should throw "An Application Pool and Database Name are required to configure the Word Automation Service Application"
            }

            It "Should return false from the test method" {
                { Test-TargetResource @testParams } | Should throw "An Application Pool and Database Name are required to configure the Word Automation Service Application"
            }

            It "Should throw an exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "An Application Pool and Database Name are required to configure the Word Automation Service Application"
            }
        } 

    } 
} 
