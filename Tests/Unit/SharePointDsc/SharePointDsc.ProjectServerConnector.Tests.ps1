[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string] 
    $SharePointCmdletModule = (Join-Path -Path $PSScriptRoot `
                                         -ChildPath "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" `
                                         -Resolve)
)

Import-Module -Name (Join-Path -Path $PSScriptRoot `
                                -ChildPath "..\UnitTestHelper.psm1" `
                                -Resolve)

$Global:SPDscHelper = New-SPDscUnitTestHelper -SharePointStubModule $SharePointCmdletModule `
                                              -SubModulePath "Modules\SharePointDsc.ProjectServer\ProjectServerConnector.psm1" `
                                              -ExcludeInvokeHelper

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        Context -Name "New-SPDscProjectServerWebService" -Fixture {

            $serviceNames = @("Admin", "Archive", "Calendar", "CubeAdmin", "CustomFields", 
            "Driver", "Events", "LookupTable", "Notifications", "ObjectLinkProvider", 
            "PortfolioAnalyses", "Project", "QueueSystem", "ResourcePlan", "Resource", 
            "Security", "Statusing", "TimeSheet", "Workflow", "WssInterop")

            $serviceNames | ForEach-Object -Process {
                $service = $_

                It "Should create a new HTTP $service web service" {
                    $serviceObject = New-SPDscProjectServerWebService -PwaUrl "http://server/pwa" `
                                                                      -EndpointName $service
                    $serviceObject.Dispose()
                }

                It "Should create a new HTTPS $service web service" {
                    $serviceObject = New-SPDscProjectServerWebService -PwaUrl "https://server/pwa" `
                                                                      -EndpointName $service
                    $serviceObject.Dispose()
                }
            }
        }

        Context -Name "Use-SPDscProjectServerWebService" -Fixture {
            
            It "disposes of a service when there is no exception" {
                $mockService = New-Object -TypeName System.IO.StringReader -ArgumentList "Example"

                Use-SPDscProjectServerWebService -Service $mockService -ScriptBlock {
                    $mockService.Read() | Out-Null
                }

                { $mockService.Read() } | Should Throw "Cannot read from a closed TextReader"
            }

            It "disposes of a service when there is an exception" {
                $mockService = New-Object -TypeName System.IO.StringReader -ArgumentList "Example"

                try
                {
                    Use-SPDscProjectServerWebService -Service $mockService -ScriptBlock {
                        throw "an error occured"
                    }
                }
                catch
                {
                    "Doing nothing with the actual exception so the test passes" | Out-Null
                }
                
                { $mockService.Read() } | Should Throw "Cannot read from a closed TextReader"
            }
        }
    }
}
