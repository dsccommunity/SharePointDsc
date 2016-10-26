[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string] 
    $SharePointCmdletModule = (Join-Path -Path $PSScriptRoot `
                                         -ChildPath "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" `
                                         -Resolve)
)

Import-Module -Name (Join-Path -Path $PSScriptRoot `
                                -ChildPath "..\SharePointDsc.TestHarness.psm1" `
                                -Resolve)

$Global:SPDscHelper = New-SPDscUnitTestHelper -SharePointStubModule $SharePointCmdletModule `
                                              -DscResource "SPWordAutomationServiceApp"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        # Initialize tests
        $getTypeFullName = "Microsoft.Office.Word.Server.Service.WordServiceApplication"

        # Mocks for all contexts   
        Mock -CommandName Remove-SPServiceApplication -MockWith {}
        Mock -CommandName Set-SPWordConversionServiceApplication -MockWith {}
        Mock -CommandName Set-SPTimerJob {}

        # Test contexts
        Context -Name "When no service applications exist in the current farm and Ensure is set to Present" -Fixture {
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

            Mock -CommandName Get-SPServiceApplication -MockWith { return $null }
            Mock -CommandName Get-SPServiceApplicationPool -MockWith {
                return @(@{ 
                    Name = $testParams.ApplicationPool
                }) 
            }
            
            Mock -CommandName New-SPWordConversionServiceApplication -MockWith {
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
                return $returnval
            }

            It "Should return absent from the Get method" { 
                (Get-TargetResource @testParams).Ensure | Should Be "absent" 
            } 

            It "Should return false when the Test method is called" { 
                Test-TargetResource @testParams | Should Be $false 
            } 

             It "Should create a new service application in the set method" { 
                Set-TargetResource @testParams 
                Assert-MockCalled New-SPWordConversionServiceApplication  
            }
        }

        Context -Name "When no service applications exist in the current farm and Ensure is set to Present, but the Application Pool does not exist" -Fixture {
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
            
            Mock -CommandName Get-SPServiceApplication -MockWith { return $null } 
            Mock -CommandName Get-SPServiceApplicationPool -MockWith { return $null }

            It "fails to create a new service application in the set method because the specified application pool is missing" { 
                { Set-TargetResource @testParams } | Should throw "Specified application pool does not exist"
            } 
        }

        Context -Name "When service applications exist in the current farm but the specific word automation app does not" -Fixture { 
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
            
            Mock -CommandName Get-SPServiceApplication -MockWith {
                $spServiceApp = [pscustomobject]@{
                    DisplayName = $testParams.Name
                }
                $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value { 
                    return @{ FullName = "Microsoft.Office.UnKnownWebServiceApplication" } 
                } -PassThru -Force
                return $spServiceApp
            }
            
            It "Should return absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"  
            }

            It "Should return false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }
        }

        Context -Name "When a service application exists and is configured correctly" -Fixture { 
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
            
            Mock -CommandName Get-SPServiceApplication -MockWith {
                $spServiceApp = [pscustomobject]@{
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
                }
                $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value { 
                    return @{ FullName = $getTypeFullName } 
                } -PassThru -Force
                return $spServiceApp
            }

            It "Should return values from the get method" { 
                Get-TargetResource @testParams | Should Not BeNullOrEmpty 
            } 

            It "Should return true when the Test method is called" { 
                Test-TargetResource @testParams | Should Be $true 
            } 
        } 

        Context -Name "When a service application exists and incorrect application pool is configured" -Fixture { 
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
            
            Mock -CommandName Get-SPServiceApplication -MockWith {
                $spServiceApp = [pscustomobject]@{
                    DisplayName = $testParams.Name 
                    ApplicationPool = @{ Name = "Wrong App Pool Name" } 
                    Database = @{
                            Name = $testParams.DatabaseName
                            Server = @{ Name = $testParams.DatabaseServer }
                    }
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
                }
                $spServiceApp = $spServiceApp | Add-Member ScriptMethod Update { 
                    $Global:SPDscSiteUseUpdated = $true 
                } -PassThru
                $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value { 
                    return @{ FullName = $getTypeFullName } 
                } -PassThru -Force
                return $spServiceApp
            }

            Mock -CommandName Get-SPServiceApplicationPool -MockWith { return @{ Name = $testParams.ApplicationPool } } 

            Mock -CommandName Get-SPTimerJob {
                $returnval = @(@{ Name = "Just a name" })
                return ,$returnval
            }

            It "Should return false when the Test method is called" { 
                Test-TargetResource @testParams | Should Be $false 
            } 

            $Global:SPDscSiteUseUpdated = $false
            It "calls Set-SPWordConversionServiceApplication and update service app cmdlet from the set method" { 
                Set-TargetResource @testParams 

                Assert-MockCalled Get-SPServiceApplicationPool 
                Assert-MockCalled Set-SPWordConversionServiceApplication 
                $Global:SPDscSiteUseUpdated | Should Be $true
            } 
        } 

        Context -Name "When a service application exists and incorrect settings are configured" -Fixture { 
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
            
            Mock -CommandName Get-SPServiceApplication -MockWith {
                $spServiceApp = [pscustomobject]@{
                    DisplayName = $testParams.Name
                    Database = @{
                            Name = $testParams.DatabaseName
                            Server = @{ Name = $testParams.DatabaseServer }
                    }
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
                }
                $spServiceApp = $spServiceApp | Add-Member ScriptMethod Update { 
                    $Global:SPDscSiteUseUpdated = $true 
                } -PassThru
                $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value { 
                    return @{ FullName = $getTypeFullName } 
                } -PassThru -Force
                return $spServiceApp
            }

            Mock -CommandName Get-SPServiceApplicationPool { return @{ Name = $testParams.ApplicationPool } } 
            Mock -CommandName Get-SPTimerJob {
                $returnval = @(@{ Name = "Just a name" })
                return ,$returnval
            }

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

        Context -Name "When no service application exists and Ensure is set to Absent" -Fixture {
            $testParams = @{ 
                Name = "Word Automation Service Application" 
                Ensure = "Absent"
            }

            Mock -CommandName Get-SPServiceApplication -MockWith { return $null } 

            It "Should return absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent" 
            }

            It "Should return true when the Test method is called" { 
                Test-TargetResource @testParams | Should Be $true 
            } 
        }

        Context -Name "When a service application exists and Ensure is set to Absent" -Fixture {
            $testParams = @{ 
                Name = "Word Automation Service Application" 
                Ensure = "Absent"
            }

            Mock -CommandName Get-SPServiceApplication -MockWith {
                $spServiceApp = [pscustomobject]@{
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
                }
                $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value { 
                    return @{ FullName = $getTypeFullName } 
                } -PassThru -Force
                return $spServiceApp
            }

            It "Should return present from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present" 
            }
            
            It "Should return true when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should call the remove service application cmdlet in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Remove-SPServiceApplication
            }
        }

        Context -Name "When Ensure is set to Absent, but another parameter is also used" -Fixture {
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

        Context -Name "When Ensure is set to Present, but the Application Pool or Database parameters are missing" -Fixture {
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

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
