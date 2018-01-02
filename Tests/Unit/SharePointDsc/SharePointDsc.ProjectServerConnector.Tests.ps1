[CmdletBinding()]
param(
    [Parameter()]
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

        Mock -CommandName Get-SPSite -MockWith {
            return @{
                WebApplication = @{
                    Url = "http://server"
                }
            }
        }

        Mock -CommandName Get-SPAuthenticationProvider -MockWith {
            return @{
                DisableKerberos = $true
            }
        }
        
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

        Mock -CommandName "Import-Module" -MockWith {}

        try
        {
            [SPDscTests.DummyWebService] | Out-Null
        }
        catch
        {
            Add-Type -TypeDefinition @"
                namespace SPDscTests
                {
                    public class DummyWebService : System.IDisposable
                    {
                        public void Dispose()
                        {

                        }
                    }
                }
"@
        }


        Context -Name "Get-SPDscProjectServerResourceName" -Fixture {

            Mock -CommandName "New-SPDscProjectServerWebService" -MockWith {
                $service = [SPDscTests.DummyWebService]::new()
                $service = $service | Add-Member -MemberType ScriptMethod `
                                                 -Name ReadResource `
                                                 -Value {
                                                     return @{
                                                        Resources = @{
                                                            WRES_ACCOUNT = "DEMO\user"
                                                        }
                                                     }
                                                 } -PassThru -Force
                return $service
            }

            It "Should return the name of a resource based on its ID" {
                Get-SPDscProjectServerResourceName -ResourceId (New-Guid) -PwaUrl "http://server/pwa" | Should Be "DEMO\user"
            }
        }

        Context -Name "Get-SPDscProjectServerResourceId" -Fixture {

            Add-Type -TypeDefinition @"

            namespace Microsoft.Office.Project.Server.Library
            {
                public class Filter
                {
                    public Filter()
                    {
                        Fields = new System.Collections.Generic.List<Microsoft.Office.Project.Server.Library.Filter.Field>();
                    }

                    public System.String FilterTableName { get; set; }

                    public System.Collections.Generic.List<Microsoft.Office.Project.Server.Library.Filter.Field> Fields { get; set; }

                    public Microsoft.Office.Project.Server.Library.Filter.FieldOperator Criteria { get; set; }

                    public System.String GetXml()
                    {
                        return "<query></query>";
                    }

                    public class Field
                    {
                        public Field(System.Object v1, System.Object v2, System.Object v3) {}
                    }

                    public class FieldOperator
                    {
                        public FieldOperator(System.Object v1, System.Object v2, System.Object v3) {}
                    }

                    public enum SortOrderTypeEnum
                    {
                        None
                    }

                    public enum FieldOperationType
                    {
                        Contain
                    }
                }
            }

"@

            Mock -CommandName "New-SPDscProjectServerWebService" -MockWith {
                $service = [SPDscTests.DummyWebService]::new()
                $service = $service | Add-Member -MemberType ScriptMethod `
                                                 -Name ReadResources `
                                                 -Value {
                                                     return @{
                                                        Resources = @{
                                                            Count = 2
                                                            Rows = @(
                                                                @{
                                                                    WRES_Account = "DEMO\user1"
                                                                    RES_UID = (New-Guid)
                                                                }
                                                                @{
                                                                    WRES_Account = "DEMO\user2"
                                                                    RES_UID = (New-Guid)
                                                                }
                                                            )
                                                        }
                                                     }
                                                 } -PassThru -Force
                return $service
            }

            It "should return the ID of a specified user" {
                Get-SPDscProjectServerResourceId -ResourceName "demo\user1" -PwaUrl "http://server/pwa" | Should Not BeNullOrEmpty
            }

            Mock -CommandName "New-SPDscProjectServerWebService" -MockWith {
                $service = [SPDscTests.DummyWebService]::new()
                $service = $service | Add-Member -MemberType ScriptMethod `
                                                 -Name ReadResources `
                                                 -Value {
                                                     return @{
                                                        Resources = @{
                                                            Count = 2
                                                            Rows = @(
                                                                @{
                                                                    WRES_Account = "DEMO\user1"
                                                                    RES_UID = (New-Guid)
                                                                }
                                                                @{
                                                                    WRES_Account = "DEMO\user2"
                                                                    RES_UID = (New-Guid)
                                                                }
                                                            )
                                                        }
                                                     }
                                                 } -PassThru -Force
                return $service
            }

            It "should throw when a user isn't in the returned data set" {
                { Get-SPDscProjectServerResourceId -ResourceName "demo\user3" -PwaUrl "http://server/pwa" } | Should Throw
            }

            Mock -CommandName "New-SPDscProjectServerWebService" -MockWith {
                $service = [SPDscTests.DummyWebService]::new()
                $service = $service | Add-Member -MemberType ScriptMethod `
                                                 -Name ReadResources `
                                                 -Value {
                                                     return @{
                                                        Resources = @{
                                                            Count = 0
                                                            Rows = @()
                                                        }
                                                     }
                                                 } -PassThru -Force
                return $service
            }

            It "should throw when no users are in the returned data set" {
                { Get-SPDscProjectServerResourceId -ResourceName "demo\user3" -PwaUrl "http://server/pwa" } | Should Throw
            }
        }

        Context -Name "Get-SPDscProjectServerGlobalPermissionId" -Fixture {

            try
            {
                [Microsoft.Office.Project.Server.Library.PSSecurityGlobalPermission] | Out-Null
            }
            catch
            {
                Add-Type -TypeDefinition @"
                    namespace Microsoft.Office.Project.Server.Library
                    {
                        public class PSSecurityGlobalPermission
                        {
                            public static System.Guid ExamplePermission {
                                get {
                                    return System.Guid.NewGuid();
                                }
                            }
                        }
                    }
"@
            }

            It "should return a value when an exiting permission is requested" {
                Get-SPDscProjectServerGlobalPermissionId -PermissionName "ExamplePermission" | Should Not BeNullOrEmpty
            }

            It "should return null when a permission that doesn't exist is requested" {
                { Get-SPDscProjectServerGlobalPermissionId -PermissionName "DoesntExist" } | Should Throw
            }
        }
    }
}
