[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule

$ModuleName = "MSFT_SPBlobCacheSettings"
Import-Module (Join-Path $RepoRoot "Modules\SharePointDSC\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "SPBlobCacheSettings" {
    InModuleScope $ModuleName {
            $testParams = @{
                WebAppUrl   = "http:/sharepoint.contoso.com"
                Zone        = "Default"
                EnableCache = $true
                Location    = "c:\BlobCache"
                MaxSize     = 30
                FileTypes   = "\.(gif|jpg|jpeg|jpe|jfif|bmp|dib|tif|tiff|themedbmp|themedcss|themedgif|themedjpg|themedpng|ico|png|wdp|hdp|css|js|asf|avi|flv|m4v|mov|mp3|mp4|mpeg|mpg|rm|rmvb|wma|wmv|ogg|ogv|oga|webm|xap)$"
            }

        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\SharePointDSC")
        
        Mock Invoke-SPDSCCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }

        Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force -ErrorAction SilentlyContinue
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue

        try { [Microsoft.SharePoint.Administration.SPUrlZone] }
        catch {
            Add-Type @"
namespace Microsoft.SharePoint.Administration {
    public enum SPUrlZone { Default, Intranet, Internet, Custom, Extranet };
}        
"@
        }

        Context "The web application doesn't exist" {
            Mock Get-SPWebApplication { return $null }

            It "throws exception from the get method" {
                { Get-TargetResource @testParams } | Should throw "Specified web application was not found."
            }

            It "throws exception from the test method" {
                { Test-TargetResource @testParams } | Should throw "Specified web application was not found."
            }

            It "throws exception from the set method" {
                { Set-TargetResource @testParams } | Should throw "Specified web application was not found."
            }
        }

#Incorrect MaxSize in WebConfig
        Context "BlobCache is enabled, but the MaxSize parameters cannot be converted to Uint16" {
            Mock Get-SPWebApplication { 
                $IISSettings = @(@{
                        Path = "c:\inetpub\wwwroot\Virtual Directories\8080"
                    })
                $iisSettingsCol = {$IISSettings}.Invoke() 

                
                $webapp = @{
                    IISSettings = $iisSettingsCol
                } 

                return $webapp
            }
            
            Mock New-Object {
                $returnval = @{
                    configuration = @{
                        SharePoint = @{
                            BlobCache = @{
                                enabled  = "true"
                                maxSize  = "30x"
                                location = "c:\BlobCache"
                                path     = "\.(gif|jpg|jpeg|jpe|jfif|bmp|dib|tif|tiff|themedbmp|themedcss|themedgif|themedjpg|themedpng|ico|png|wdp|hdp|css|js|asf|avi|flv|m4v|mov|mp3|mp4|mpeg|mpg|rm|rmvb|wma|wmv|ogg|ogv|oga|webm|xap)$"
                            }
                        }
                    }
                }
                
                $returnval = $returnval | Add-Member ScriptMethod Load { } -PassThru | Add-Member ScriptMethod Save { $Global:SharePointDSCWebConfigUpdated = $true } -PassThru
                
                return $returnval
            } -ParameterFilter { $TypeName -eq "XML" }
            
            Mock Copy-Item {}

            It "returns exception from the get method" {
                { Get-TargetResource @testParams } | Should throw "Conversion of MaxSize failed"
            }

            It "returns exception from the test method" {
                { Test-TargetResource @testParams } | Should throw "Conversion of MaxSize failed"
            }
            
            It "returns exception from the set method" {
                { Set-TargetResource @testParams } | Should throw "Conversion of MaxSize failed"
            }
        }

        Context "BlobCache is enabled, but the other parameters do not match" {
            Mock Get-SPWebApplication { 
                $IISSettings = @(@{
                        Path = "c:\inetpub\wwwroot\Virtual Directories\8080"
                    })
                $iisSettingsCol = {$IISSettings}.Invoke() 

                
                $webapp = @{
                    IISSettings = $iisSettingsCol
                } 

                return $webapp
            }
            
            Mock New-Object {
                $returnval = @{
                    configuration = @{
                        SharePoint = @{
                            BlobCache = @{
                                enabled  = "true"
                                maxSize  = "20"
                                location = "d:\BlobCache"
                                path     = "\.(csv|gif|jpg|jpeg|jpe|jfif|bmp|dib|tif|tiff|themedbmp|themedcss|themedgif|themedjpg|themedpng|ico|png|wdp|hdp|css|js|asf|avi|flv|m4v|mov|mp3|mp4|mpeg|mpg|rm|rmvb|wma|wmv|ogg|ogv|oga|webm|xap)$"
                            }
                        }
                    }
                }
                
                $returnval = $returnval | Add-Member ScriptMethod Load { } -PassThru | Add-Member ScriptMethod Save { $Global:SharePointDSCWebConfigUpdated = $true } -PassThru
                
                return $returnval
            } -ParameterFilter { $TypeName -eq "XML" }
            
            Mock Copy-Item {}

            It "returns values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
            
            $Global:SharePointDSCWebConfigUpdated = $false
            It "returns true from the set method" {
                Set-TargetResource @testParams
                $Global:SharePointDSCWebConfigUpdated | Should Be $true
            }
        }
        
        Context "BlobCache is disabled, but the parameters specify it to be enabled" {
            Mock Get-SPWebApplication { 
                $IISSettings = @(@{
                        Path = "c:\inetpub\wwwroot\Virtual Directories\8080"
                    })
                $iisSettingsCol = {$IISSettings}.Invoke() 

                
                $webapp = @{
                    IISSettings = $iisSettingsCol
                } 

                return $webapp
            }
            
            Mock New-Object {
                $returnval = @{
                    configuration = @{
                        SharePoint = @{
                            BlobCache = @{
                                enabled  = "false"
                                maxSize  = "30"
                                location = "c:\BlobCache"
                                path     = "\.(gif|jpg|jpeg|jpe|jfif|bmp|dib|tif|tiff|themedbmp|themedcss|themedgif|themedjpg|themedpng|ico|png|wdp|hdp|css|js|asf|avi|flv|m4v|mov|mp3|mp4|mpeg|mpg|rm|rmvb|wma|wmv|ogg|ogv|oga|webm|xap)$"
                            }
                        }
                    }
                }
                
                $returnval = $returnval | Add-Member ScriptMethod Load { } -PassThru | Add-Member ScriptMethod Save { $Global:SharePointDSCWebConfigUpdated = $true } -PassThru
                
                return $returnval
            } -ParameterFilter { $TypeName -eq "XML" }
            
            Mock Copy-Item {}

            It "returns values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
            
            $Global:SharePointDSCWebConfigUpdated = $false
            It "returns true from the set method" {
                Set-TargetResource @testParams
                $Global:SharePointDSCWebConfigUpdated | Should Be $true
            }
        }

        Context "The specified configuration is correctly configured" {
            Mock Get-SPWebApplication { 
                $IISSettings = @(@{
                        Path = "c:\inetpub\wwwroot\Virtual Directories\8080"
                    })
                $iisSettingsCol = {$IISSettings}.Invoke() 

                
                $webapp = @{
                    IISSettings = $iisSettingsCol
                } 

                return $webapp
            }
            
            Mock New-Object {
                $returnval = @{
                    configuration = @{
                        SharePoint = @{
                            BlobCache = @{
                                enabled  = "true"
                                maxSize  = "30"
                                location = "c:\BlobCache"
                                path     = "\.(gif|jpg|jpeg|jpe|jfif|bmp|dib|tif|tiff|themedbmp|themedcss|themedgif|themedjpg|themedpng|ico|png|wdp|hdp|css|js|asf|avi|flv|m4v|mov|mp3|mp4|mpeg|mpg|rm|rmvb|wma|wmv|ogg|ogv|oga|webm|xap)$"
                            }
                        }
                    }
                }
                
                $returnval = $returnval | Add-Member ScriptMethod Load { } -PassThru | Add-Member ScriptMethod Save { } -PassThru
                
                return $returnval
            } -ParameterFilter { $TypeName -eq "XML" }

            It "returns values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
        
        Context "BlobCache is enabled, but the parameters specify it to be disabled" {
            $testParams = @{
                WebAppUrl   = "http:/sharepoint.contoso.com"
                Zone        = "Default"
                EnableCache = $false
            }

            Mock Get-SPWebApplication { 
                $IISSettings = @(@{
                        Path = "c:\inetpub\wwwroot\Virtual Directories\8080"
                    })
                $iisSettingsCol = {$IISSettings}.Invoke() 

                
                $webapp = @{
                    IISSettings = $iisSettingsCol
                } 

                return $webapp
            }
            
            Mock New-Object {
                $returnval = @{
                    configuration = @{
                        SharePoint = @{
                            BlobCache = @{
                                enabled  = "true"
                                maxSize  = "30"
                                location = "c:\BlobCache"
                                path     = "\.(gif|jpg|jpeg|jpe|jfif|bmp|dib|tif|tiff|themedbmp|themedcss|themedgif|themedjpg|themedpng|ico|png|wdp|hdp|css|js|asf|avi|flv|m4v|mov|mp3|mp4|mpeg|mpg|rm|rmvb|wma|wmv|ogg|ogv|oga|webm|xap)$"
                            }
                        }
                    }
                }
                
                $returnval = $returnval | Add-Member ScriptMethod Load { } -PassThru | Add-Member ScriptMethod Save { $Global:SharePointDSCWebConfigUpdated = $true } -PassThru
                
                return $returnval
            } -ParameterFilter { $TypeName -eq "XML" }
            
            Mock Copy-Item {}

            It "returns values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
            
            $Global:SharePointDSCWebConfigUpdated = $false
            It "returns true from the set method" {
                Set-TargetResource @testParams
                $Global:SharePointDSCWebConfigUpdated | Should Be $true
            }
        }


    }    
}
