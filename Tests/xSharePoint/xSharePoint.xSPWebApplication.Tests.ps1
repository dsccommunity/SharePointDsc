[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4693.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule

$ModuleName = "MSFT_xSPWebApplication"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\Modules\xSharePoint.Util\xSharePoint.Util.psm1")

Describe "xSPWebApplication" {
    InModuleScope $ModuleName {
        $testParams = @{
            Name = "SharePoint Sites"
            ApplicationPool = "SharePoint Web Apps"
            ApplicationPoolAccount = "DEMO\ServiceAccount"
            Url = "http://sites.sharepoint.com"
            AuthenticationMethod = "NTLM"
        }
        
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\xSharePoint")
        
        Mock Invoke-xSharePointCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue
        
        Mock New-SPAuthenticationProvider { }
        Mock New-SPWebApplication { }

        Context "The web application that uses NTLM doesn't exist but should" {
            Mock Get-SPWebApplication { return $null }

            It "returns null from the get method" {
                Get-TargetResource @testParams | Should BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "calls the new cmdlet from the set method" {
                Set-TargetResource @testParams

                Assert-MockCalled New-SPWebApplication
                Assert-MockCalled New-SPAuthenticationProvider -ParameterFilter { $DisableKerberos -eq $true }
            }

            $testParams.Add("InstallAccount", (New-Object System.Management.Automation.PSCredential ("username", (ConvertTo-SecureString "password" -AsPlainText -Force))))
            It "calls the new cmdlet from the set method where InstallAccount is used" {
                Set-TargetResource @testParams

                Assert-MockCalled New-SPWebApplication
                Assert-MockCalled New-SPAuthenticationProvider -ParameterFilter { $DisableKerberos -eq $true }
            }
            $testParams.Remove("InstallAccount")

            $testParams.Add("AllowAnonymous", $true)
            It "calls the new cmdlet from the set where anonymous authentication is requested" {
                Set-TargetResource @testParams

                Assert-MockCalled New-SPWebApplication
                Assert-MockCalled New-SPAuthenticationProvider -ParameterFilter { $DisableKerberos -eq $true }
            }
            $testParams.Remove("AllowAnonymous")
        }

        $testParams.AuthenticationMethod = "Kerberos"

        Context "The web application that uses Kerberos doesn't exist but should" {
            Mock Get-SPWebApplication { return $null }

            It "returns null from the get method" {
                Get-TargetResource @testParams | Should BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "calls the new cmdlet from the set method" {
                Set-TargetResource @testParams

                Assert-MockCalled New-SPWebApplication
            }
        }

        $testParams.AuthenticationMethod = "NTLM"

        Context "The web appliation does exist and should that uses NTLM" {
            Mock Get-SPAuthenticationProvider { return @{ DisableKerberos = $true; AllowAnonymous = $false } }
            Mock Get-SPWebApplication { return @(@{
                DisplayName = $testParams.Name
                ApplicationPool = @{ 
                    Name = $testParams.ApplicationPool
                    Username = $testParams.ApplicationPoolAccount
                }
                ContentDatabases = @(
                    @{
                        Name = "SP_Content_01"
                        Server = "sql.domain.local"
                    }
                )
                IisSettings = @( 
                    @{ Path = "C:\inetpub\wwwroot\something" }
                )
                Url = $testParams.Url
            })}

            It "returns the current data from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        $testParams.AuthenticationMethod = "Kerberos"

        Context "The web appliation does exist and should that uses Kerberos" {
            Mock Get-SPAuthenticationProvider { return @{ DisableKerberos = $false; AllowAnonymous = $false } }
            Mock Get-SPWebApplication { return @(@{
                DisplayName = $testParams.Name
                ApplicationPool = @{ 
                    Name = $testParams.ApplicationPool
                    Username = $testParams.ApplicationPoolAccount
                }
                ContentDatabases = @(
                    @{
                        Name = "SP_Content_01"
                        Server = "sql.domain.local"
                    }
                )
                IisSettings = @( 
                    @{ Path = "C:\inetpub\wwwroot\something" }
                )
                Url = $testParams.Url
            })}

            It "returns the current data from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
        

    
       $testParams = @{
            Name = "Complex types Web App"
            ApplicationPool = "SharePoint complex type Web App"
            ApplicationPoolAccount = "DEMO\ServiceAccount"
            Url = "http://sites.sharepoint.com"
            AuthenticationMethod = "NTLM"
            BlockedFileTypes = @{
                Blocked  = @("java", "vbs", "exe","xxx")
                EnsureBlocked  = @("java", "rar", "exe","xxx")
                EnsureAllowed  = @("exe", "vbs","zip")
           }
            WorkflowSettings = @{
                ExternalWorkflowParticipantsEnabled=$false
                UserDefinedWorkflowsEnabled=$true
                EmailToNoPermissionWorkflowParticipantsEnable=$false
           }
           ThrottlingSettings = @{
                ListViewThreshold = 10000
                AllowObjectModelOverride = $true
                AdminThreshold=55000
                ListViewLookupThreshold=10
                HappyHourEnabled= $true
                HappyHour = @{
                    Hour = 20
                    Minute = 5
                    Duration = 2
                }
                UniquePermissionThreshold = 133000
                RequestThrottling=$false
                ChangeLogEnabled=$true
                ChangeLogExpiryDays = 19
                EventHandlersEnabled=$true
           }
           GeneralSettings=@{
                    TimeZone = 10
                    DefaultQuotaTemplate = ""
                    Alerts = $true
                    AlertsLimit = 10
                    RSS = $true
                    BlogAPI = $true
                    BlogAPIAuthenticated = $true
                    BrowserFileHandling = "Permissive"
                    SecurityValidation = $true
                    RecycleBinEnabled = $true
                    SecondStageRecycleBinEnabled = $true
                    RecycleBinCleanupEnabled =  $true
                    RecycleBinRetentionPeriod = 10
                    SecondStageRecycleBinQuota = 500
                    MaximumUploadSize = 555
                    CustomerExperienceProgram = $true
                    PresenceEnabled = $true
                    }

        }

        Context "set target resorce works with complex types filled in" {
            Mock Get-SPAuthenticationProvider { return @{ DisableKerberos = $false; AllowAnonymous = $false } }
            
            $mockedapp= {  
                $result= @(@{
                    DisplayName = $testParams.Name
                    ApplicationPool = @{ 
                        Name = $testParams.ApplicationPool
                        Username = $testParams.ApplicationPoolAccount
                    }
                    ContentDatabases = @(
                        @{
                            Name = "SP_Content_01"
                            Server = "sql.domain.local"
                        }
                    )
                    IisSettings = @( 
                        @{ Path = "C:\inetpub\wwwroot\something" }
                    )
                    Url = $testParams.Url
                    MaxItemsPerThrottledOperation=5000
                    AllowOMCodeOverrideThrottleSettings=$true
                    MaxItemsPerThrottledOperationOverride = 10000
                    MaxQueryLookupFields =  8
                    UnthrottledPrivilegedOperationWindowEnabled =$true
                    DailyStartUnthrottledPrivilegedOperationsHour = $null 
                    DailyStartUnthrottledPrivilegedOperationsMinute = $null
                    DailyUnthrottledPrivilegedOperationsDuration = $null

                    MaxUniquePermScopesPerList = 50000
                    EventHandlersEnabled = $true
                    HttpThrottleSettings = @{
                        PerformThrottle = $true
                    }
                    FormDigestSettings = @{
                        Enabled =$true 
                    }
                    ChangeLogExpirationEnabled = $true
                    ChangeLogRetentionPeriod = New-TimeSpan -Days 10
                })
              
                $result=  $result | Add-Member  ScriptMethod UpdateWorkflowConfigurationSettings { 
                    $Global:UpdateWorkflowCalled = $true;
                } -PassThru

               $blockedFileTypes = new-object PSObject 

               $blockedFileTypes =  $blockedFileTypes | Add-Member  ScriptMethod Remove { 
                    $Global:BlockedFilesRemoveCalled = $true;
                    return $true;
                } -passThru
               $blockedFileTypes =  $blockedFileTypes | Add-Member  ScriptMethod Clear { 
                    $Global:BlockedFilesClearCalled = $true;
                    return $true;
                } -passThru

                $blockedFileTypes =  $blockedFileTypes | Add-Member  ScriptMethod ContainExtension { 

                    param($extension)
                    $Global:BlockedFilesContainsCalled = $true;
                    if($extension -eq "exe"){
                        return $true
                    }
                    return $false
                    
                } -passThru
               $blockedFileTypes = $blockedFileTypes | Add-Member  ScriptMethod Add {
                    param( [string]$fileType)
                    $Global:BlockedFilesAddCalled = $true;
                    return $true;
                } -passThru
                
                $result=$result| Add-Member  ScriptMethod Update { 
                    $Global:SPWebApplicationUpdateCalled = $true;
                    return $true;               
                } -PassThru
                $result= $result | Add-Member NoteProperty  -value $blockedFileTypes -Name "BlockedFileExtensions" -PassThru
                return $result
            }
            Mock Get-SPWebApplication $mockedapp
            Mock New-SPWebApplication $mockedapp

            It "calls the new cmdlet from the set method and does update blockedFileExtensions" {
                $Global:BlockedFilesAddCalled = $false;
                $Global:BlockedFilesClearCalled = $false;
                $Global:BlockedFilesRemoveCalled = $false;
                $Global:BlockedFilesContainsCalled = $false;
                $Global:SPWebApplicationUpdateCalled =$false ;
                Set-TargetResource @testParams
                $Global:BlockedFilesAddCalled| Should be  $true;
                $Global:BlockedFilesContainsCalled| Should be  $true;
                $Global:SPWebApplicationUpdateCalled| Should be  $true;
                $Global:BlockedFilesRemoveCalled| Should be  $true;

                Assert-MockCalled Get-SPWebApplication
            }

        }
 

    }    
}