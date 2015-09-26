function Invoke-xSharePointCommand() {
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $Credential,

        [parameter(Mandatory = $false)]
        [HashTable]
        $Arguments,


        [parameter(Mandatory = $true)]
        [ScriptBlock]
        $ScriptBlock
    )

    $VerbosePreference = 'Continue'

    $invokeArgs = @{
        ScriptBlock = [ScriptBlock]::Create("if (`$null -eq (Get-PSSnapin -Name Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue)) {Add-PSSnapin Microsoft.SharePoint.PowerShell}; " + $ScriptBlock.ToString())
    }
    if ($null -ne $Arguments) {
        $invokeArgs.Add("ArgumentList", $Arguments)
    }

    if ($null -eq $Credential) {
        if ($Env:USERNAME.Contains("$")) {
            throw [Exception] "You need to specify a value for either InstallAccount or PsDscRunAsCredential."
            return
        }
        Write-Verbose "Executing as the local run as user $($Env:USERDOMAIN)\$($Env:USERNAME)" 

        $result = Invoke-Command @invokeArgs -Verbose
        return $result
    } else {
        if ($Credential.UserName.Split("\")[1] -eq $Env:USERNAME) { 
            if (-not $Env:USERNAME.Contains("$")) {
                throw [Exception] "Unable to use both InstallAccount and PsDscRunAsCredential in a single resource. Remove one and try again."
                return
            }
        }
        Write-Verbose "Executing using a provided credential and local PSSession as user $($Credential.UserName)"

        #Running garbage collection to resolve issues related to Azure DSC extention use
        [GC]::Collect()

        $session = New-PSSession -ComputerName $env:COMPUTERNAME -Credential $Credential -Authentication CredSSP -Name "Microsoft.SharePoint.DSC" -SessionOption (New-PSSessionOption -OperationTimeout 0 -IdleTimeout 60000) -ErrorAction Continue
        
        if ($session) { $invokeArgs.Add("Session", $session) }

        $result = Invoke-Command @invokeArgs -Verbose

        if ($session) { Remove-PSSession $session } 
        return $result
    }
}

function Rename-xSharePointParamValue() {
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true,Position=1,ValueFromPipeline=$true)]
        $params,

        [parameter(Mandatory = $true,Position=2)]
        $oldName,

        [parameter(Mandatory = $true,Position=3)]
        $newName
    )

    if ($params.ContainsKey($oldName)) {
        $params.Add($newName, $params.$oldName)
        $params.Remove($oldName) | Out-Null
    }
    return $params
}

function Get-xSharePointInstalledProductVersion() {
    $pathToSearch = "C:\Program Files\Common Files\microsoft shared\Web Server Extensions\*\ISAPI\Microsoft.SharePoint.dll"
    $fullPath = Get-Item $pathToSearch | Sort-Object { $_.Directory } -Descending | Select-Object -First 1
    return (Get-Command $fullPath).FileVersionInfo
}

function Get-xSharePointAssemblyVersion() {
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true,Position=1)]
        [string]
        $PathToAssembly
    )
    return (Get-Command $PathToAssembly).FileVersionInfo.FileMajorPart
}

function Update-xSharePointObject() {
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true,Position=1)]
        [object]
        $InputObject
    )
    $InputObject.Update()
}

function Test-xSharePointSpecificParameters() {
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true,Position=1)]
        [HashTable]
        $CurrentValues,

        [parameter(Mandatory = $true,Position=2)]
        [HashTable]
        $DesiredValues,

        [parameter(Mandatory = $false,Position=3)]
        [Array]
        $ValuesToCheck
    )

    $returnValue = $true

    if (($ValuesToCheck -eq $null) -or ($ValuesToCheck.Count -lt 1)) {
        $KeyList = $DesiredValues.Keys
    } else {
        $KeyList = $ValuesToCheck
    }

    $KeyList | ForEach-Object {
        if ($_ -ne "Verbose") {
            if (($CurrentValues.ContainsKey($_) -eq $false) -or ($CurrentValues.$_ -ne $DesiredValues.$_)) {
                if ($DesiredValues.ContainsKey($_)) {
                    $desiredType = $DesiredValues.$_.GetType()
                    $fieldName = $_
                    switch ($desiredType.Name) {
                        "String" {
                            if ([string]::IsNullOrEmpty($CurrentValues.$fieldName) -and [string]::IsNullOrEmpty($DesiredValues.$fieldName)) {} else {
                                $returnValue = $false
                            }
                        }
                        "Int32" {
                            if (($DesiredValues.$fieldName -eq 0) -and ($CurrentValues.$fieldName -eq $null)) {} else {
                                $returnValue = $false
                            }
                        }
                        default {
                            $returnValue = $false
                        }
                    }
                }            
            }
        }
        
    }
    return $returnValue
}

Export-ModuleMember -Function *
