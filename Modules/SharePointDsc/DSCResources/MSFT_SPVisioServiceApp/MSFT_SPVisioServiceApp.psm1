function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)] 
        [System.String] 
        $Name,

        [parameter(Mandatory = $true)]
        [System.String] 
        $ApplicationPool,

        [parameter(Mandatory = $false)]
        [System.String] 
        $ProxyName,

        [parameter(Mandatory = $false)] 
        [ValidateSet("Present","Absent")] 
        [System.String] 
        $Ensure = "Present",

        [parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Getting Visio Graphics service app '$Name'"

    $result = Invoke-SPDSCCommand -Credential $InstallAccount `
                                  -Arguments $PSBoundParameters `
                                  -ScriptBlock {
        $params = $args[0]
    
        $serviceApps = Get-SPServiceApplication -Name $params.Name `
                                                -ErrorAction SilentlyContinue
        $nullReturn = @{
            Name = $params.Name
            ApplicationPool = $params.ApplicationPool
            Ensure = "Absent"
        } 
        if ($null -eq $serviceApps) 
        { 
            return $nullReturn
        }
        $serviceApp = $serviceApps | Where-Object -FilterScript { 
            $_.GetType().FullName -eq "Microsoft.Office.Visio.Server.Administration.VisioGraphicsServiceApplication"
        }

        if ($null -eq $serviceApp) 
        { 
            return $nullReturn
        } 
        else 
        {
            return @{
                Name = $serviceApp.DisplayName
                ApplicationPool = $serviceApp.ApplicationPool.Name
                Ensure = "Present"
                InstallAccount = $params.InstallAccount
            }
        }
    }
    return $result
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)] 
        [System.String] 
        $Name,

        [parameter(Mandatory = $true)]
        [System.String] 
        $ApplicationPool,

        [parameter(Mandatory = $false)]
        [System.String] 
        $ProxyName,

        [parameter(Mandatory = $false)] 
        [ValidateSet("Present","Absent")] 
        [System.String] 
        $Ensure = "Present",

        [parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Setting Visio Graphics service app '$Name'"

    $result = Get-TargetResource @PSBoundParameters

    if ($result.Ensure -eq "Absent" -and $Ensure -eq "Present") 
    { 
        Write-Verbose -Message "Creating Visio Graphics Service Application $Name"
        Invoke-SPDSCCommand -Credential $InstallAccount `
                            -Arguments $PSBoundParameters `
                            -ScriptBlock {
            $params = $args[0]
        
            $visioApp = New-SPVisioServiceApplication -Name $params.Name `
                                      -ApplicationPool $params.ApplicationPool
            if ($params.ContainsKey("ProxyName"))
            {
                $pName = $params.ProxyName
                $params.Remove("ProxyName") | Out-Null 
            }

            if ($null -eq $pName) {
                $pName = "$($params.Name) Proxy"
            }
            if ($null -ne $visioApp)
            {
                $visioProxy = New-SPVisioServiceApplicationProxy -Name $pName -ServiceApplication $params.Name
            }
        }
    }
    if ($result.Ensure -eq "Present" -and $Ensure -eq "Present") 
    {
        if ($ApplicationPool -ne $result.ApplicationPool) 
        {
            Write-Verbose -Message "Updating Visio Graphics Service Application $Name"
            Invoke-SPDSCCommand -Credential $InstallAccount `
                                -Arguments $PSBoundParameters `
                                -ScriptBlock {
                $params = $args[0]               

                $appPool = Get-SPServiceApplicationPool -Identity $params.ApplicationPool

                Get-SPServiceApplication -Name $params.Name `
                    | Where-Object -FilterScript { 
                        $_.GetType().FullName -eq "Microsoft.Office.Visio.Server.Administration.VisioGraphicsServiceApplication"
                    } | Set-SPVisioServiceApplication -ServiceApplicationPool $appPool
            }
        }
    }
    
    if ($Ensure -eq "Absent") 
    {
        Write-Verbose -Message "Removing Visio service application $Name"
        Invoke-SPDSCCommand -Credential $InstallAccount `
                            -Arguments $PSBoundParameters `
                            -ScriptBlock {
            $params = $args[0]
            
            $app = Get-SPServiceApplication -Name $params.Name `
                    | Where-Object -FilterScript { 
                        $_.GetType().FullName -eq "Microsoft.Office.Visio.Server.Administration.VisioGraphicsServiceApplication"
                    }

            $proxies = Get-SPServiceApplicationProxy
            foreach($proxyInstance in $proxies)
            {
                if($app.IsConnected($proxyInstance))
                {
                    $proxyInstance.Delete()
                }
            }

            Remove-SPServiceApplication -Identity $app -Confirm:$false
        }
    }   
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)] 
        [System.String] 
        $Name,

        [parameter(Mandatory = $true)]
        [System.String] 
        $ApplicationPool,

        [parameter(Mandatory = $false)]
        [System.String] 
        $ProxyName,

        [parameter(Mandatory = $false)] 
        [ValidateSet("Present","Absent")] 
        [System.String] 
        $Ensure = "Present",

        [parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )
    
    Write-Verbose -Message "Testing Visio Graphics service app '$Name'"

    $PSBoundParameters.Ensure = $Ensure

    $CurrentValues = Get-TargetResource @PSBoundParameters

    return Test-SPDscParameterState -CurrentValues $CurrentValues `
                                    -DesiredValues $PSBoundParameters `
                                    -ValuesToCheck @("ApplicationPool", "Ensure")
}

Export-ModuleMember -Function *-TargetResource
