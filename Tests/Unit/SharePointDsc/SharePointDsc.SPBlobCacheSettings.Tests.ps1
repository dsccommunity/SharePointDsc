[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule

$ModuleName = "MSFT_SPBlobCacheSettings"
Import-Module (Join-Path $RepoRoot "Modules\SharePointDSC\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "SPBlobCacheSettings" {
    InModuleScope $ModuleName {
            $testParams = @{
                WebAppUrl   = "http://sharepoint.contoso.com"
                Zone        = "Default"
                EnableCache = $true
                Location    = "c:\BlobCache"
                MaxSizeInGB     = 30
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

        $webConfigPath = "TestDrive:\inetpub\wwwroot\Virtual Directories\8080"
        New-Item $webConfigPath -ItemType Directory

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

        Context "BlobCache is enabled, but the MaxSize parameters cannot be converted to Uint16" {
            Set-Content (Join-Path $webConfigPath "web.config") -value '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<configuration>
  <SharePoint>
    <BlobCache location="c:\BlobCache" path="\.(gif|jpg|jpeg|jpe|jfif|bmp|dib|tif|tiff|themedbmp|themedcss|themedgif|themedjpg|themedpng|ico|png|wdp|hdp|css|js|asf|avi|flv|m4v|mov|mp3|mp4|mpeg|mpg|rm|rmvb|wma|wmv|ogg|ogv|oga|webm|xap)$" maxSize="30x" enabled="True" />
  </SharePoint>
</configuration>'

            Mock Get-SPWebApplication { 
                $IISSettings = @(@{
                        Path = (Join-Path (Join-Path (Get-PSDrive TestDrive).Root (Get-PSDrive TestDrive).CurrentLocation) "inetpub\wwwroot\Virtual Directories\8080")
                    })
                $iisSettingsCol = {$IISSettings}.Invoke() 

                
                $webapp = @{
                    IISSettings = $iisSettingsCol
                } 

                return $webapp
            }

            Mock Test-Path { return $true }

            Mock Copy-Item {}

            It "returns 0 from the get method" {
                (Get-TargetResource @testParams).MaxSizeInGB | Should Be 0
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams  | Should Be $false
            }
            
            It "returns MaxSize 30 in web.config from the set method" {
                Set-TargetResource @testParams
                [xml] $webcfg = Get-Content (Join-Path $webConfigPath "web.config")
                $webcfg.configuration.SharePoint.BlobCache.maxsize | Should Be "30" 
            }
        }

        Context "BlobCache correctly configured, but the folder does not exist" {
            Set-Content (Join-Path $webConfigPath "web.config") -value '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<configuration>
  <SharePoint>
    <BlobCache location="c:\BlobCache" path="\.(gif|jpg|jpeg|jpe|jfif|bmp|dib|tif|tiff|themedbmp|themedcss|themedgif|themedjpg|themedpng|ico|png|wdp|hdp|css|js|asf|avi|flv|m4v|mov|mp3|mp4|mpeg|mpg|rm|rmvb|wma|wmv|ogg|ogv|oga|webm|xap)$" maxSize="30" enabled="True" />
  </SharePoint>
</configuration>'

            Mock Get-SPWebApplication { 
                $IISSettings = @(@{
                        Path = (Join-Path (Join-Path (Get-PSDrive TestDrive).Root (Get-PSDrive TestDrive).CurrentLocation) "inetpub\wwwroot\Virtual Directories\8080")
                    })
                $iisSettingsCol = {$IISSettings}.Invoke() 

                
                $webapp = @{
                    IISSettings = $iisSettingsCol
                } 

                return $webapp
            }
            
            Mock Test-Path { return $false }
            Mock New-Item {}

            Mock Copy-Item {}

            It "returns values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
            
            It "check if function is called in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled New-Item
            }
        }

        Context "BlobCache is enabled, but the other parameters do not match" {
            Set-Content (Join-Path $webConfigPath "web.config") -value '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<configuration>
  <SharePoint>
    <BlobCache location="c:\BlobCache" path="\.(csv|gif|jpg|jpeg|jpe|jfif|bmp|dib|tif|tiff|themedbmp|themedcss|themedgif|themedjpg|themedpng|ico|png|wdp|hdp|css|js|asf|avi|flv|m4v|mov|mp3|mp4|mpeg|mpg|rm|rmvb|wma|wmv|ogg|ogv|oga|webm|xap)$" maxSize="20" enabled="True" />
  </SharePoint>
</configuration>'

            Mock Get-SPWebApplication { 
                $IISSettings = @(@{
                        Path = (Join-Path (Join-Path (Get-PSDrive TestDrive).Root (Get-PSDrive TestDrive).CurrentLocation) "inetpub\wwwroot\Virtual Directories\8080")
                    })
                $iisSettingsCol = {$IISSettings}.Invoke() 

                
                $webapp = @{
                    IISSettings = $iisSettingsCol
                } 

                return $webapp
            }
            
            Mock Test-Path { return $true }

            Mock Copy-Item {}

            It "returns values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
            
            It "returns MaxSize 30 from the set method" {
                Set-TargetResource @testParams
                [xml] $webcfg = Get-Content (Join-Path $webConfigPath "web.config")
                $webcfg.configuration.SharePoint.BlobCache.maxsize | Should Be "30" 
            }
        }
        
        Context "BlobCache is disabled, but the parameters specify it to be enabled" {
            Set-Content (Join-Path $webConfigPath "web.config") -value '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<configuration>
  <SharePoint>
    <BlobCache location="c:\BlobCache" path="\.(gif|jpg|jpeg|jpe|jfif|bmp|dib|tif|tiff|themedbmp|themedcss|themedgif|themedjpg|themedpng|ico|png|wdp|hdp|css|js|asf|avi|flv|m4v|mov|mp3|mp4|mpeg|mpg|rm|rmvb|wma|wmv|ogg|ogv|oga|webm|xap)$" maxSize="20" enabled="False" />
  </SharePoint>
</configuration>'

            Mock Get-SPWebApplication { 
                $IISSettings = @(@{
                        Path = (Join-Path (Join-Path (Get-PSDrive TestDrive).Root (Get-PSDrive TestDrive).CurrentLocation) "inetpub\wwwroot\Virtual Directories\8080")
                    })
                $iisSettingsCol = {$IISSettings}.Invoke() 

                
                $webapp = @{
                    IISSettings = $iisSettingsCol
                } 

                return $webapp
            }
            
            Mock Test-Path { return $true }

            Mock Copy-Item {}

            It "returns values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
            
            It "returns Enabled False from the set method" {
                Set-TargetResource @testParams
                [xml] $webcfg = Get-Content (Join-Path $webConfigPath "web.config")
                $webcfg.configuration.SharePoint.BlobCache.enabled | Should Be "True" 
            }
        }

        Context "The specified configuration is correctly configured" {
            Set-Content (Join-Path $webConfigPath "web.config") -value '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<configuration>
  <SharePoint>
    <BlobCache location="c:\BlobCache" path="\.(gif|jpg|jpeg|jpe|jfif|bmp|dib|tif|tiff|themedbmp|themedcss|themedgif|themedjpg|themedpng|ico|png|wdp|hdp|css|js|asf|avi|flv|m4v|mov|mp3|mp4|mpeg|mpg|rm|rmvb|wma|wmv|ogg|ogv|oga|webm|xap)$" maxSize="30" enabled="True" />
  </SharePoint>
</configuration>'

            Mock Get-SPWebApplication { 
                $IISSettings = @(@{
                        Path = (Join-Path (Join-Path (Get-PSDrive TestDrive).Root (Get-PSDrive TestDrive).CurrentLocation) "inetpub\wwwroot\Virtual Directories\8080")
                    })
                $iisSettingsCol = {$IISSettings}.Invoke() 

                
                $webapp = @{
                    IISSettings = $iisSettingsCol
                } 

                return $webapp
            }
            
            Mock Test-Path { return $true }

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

            Set-Content (Join-Path $webConfigPath "web.config") -value '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<configuration>
  <SharePoint>
    <BlobCache location="c:\BlobCache" path="\.(gif|jpg|jpeg|jpe|jfif|bmp|dib|tif|tiff|themedbmp|themedcss|themedgif|themedjpg|themedpng|ico|png|wdp|hdp|css|js|asf|avi|flv|m4v|mov|mp3|mp4|mpeg|mpg|rm|rmvb|wma|wmv|ogg|ogv|oga|webm|xap)$" maxSize="30" enabled="True" />
  </SharePoint>
</configuration>'

            Mock Get-SPWebApplication { 
                $IISSettings = @(@{
                        Path = (Join-Path (Join-Path (Get-PSDrive TestDrive).Root (Get-PSDrive TestDrive).CurrentLocation) "inetpub\wwwroot\Virtual Directories\8080")
                    })
                $iisSettingsCol = {$IISSettings}.Invoke() 

                
                $webapp = @{
                    IISSettings = $iisSettingsCol
                } 

                return $webapp
            }
                        
            Mock Test-Path { return $true }

            Mock Copy-Item {}

            It "returns values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
            
            It "returns true from the set method" {
                Set-TargetResource @testParams
                [xml] $webcfg = Get-Content (Join-Path $webConfigPath "web.config")
                $webcfg.configuration.SharePoint.BlobCache.enabled | Should Be "False" 
            }
        }


    }    
}
