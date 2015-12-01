function Add-xSharePointUserToLocalAdmin() {
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true,Position=1)] [string] $UserName
    )

    if ($UserName.Contains("\") -eq $false) {
        throw [Exception] "Usernames should be formatted as domain\username"
    }

    $domainName = $UserName.Split('\')[0]
    $accountName = $UserName.Split('\')[1]

    Write-Verbose -Message "Adding $domainName\$userName to local admin group"
    ([ADSI]"WinNT://$($env:computername)/Administrators,group").Add("WinNT://$domainName/$accountName") | Out-Null
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

function Get-xSharePointContentService() {
    [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint") | Out-Null
    return [Microsoft.SharePoint.Administration.SPWebService]::ContentService
}

function Get-xSharePointInstalledProductVersion() {
    $pathToSearch = "C:\Program Files\Common Files\microsoft shared\Web Server Extensions\*\ISAPI\Microsoft.SharePoint.dll"
    $fullPath = Get-Item $pathToSearch | Sort-Object { $_.Directory } -Descending | Select-Object -First 1
    return (Get-Command $fullPath).FileVersionInfo
}

function Invoke-xSharePointCommand() {
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $Credential,
        [parameter(Mandatory = $false)] [Object[]]    $Arguments,
        [parameter(Mandatory = $true)]  [ScriptBlock] $ScriptBlock
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

        try {
            $result = Invoke-Command @invokeArgs -Verbose
        } catch {
            if ($_.Exception.Message.Contains("An update conflict has occurred, and you must re-try this action")) {
                Write-Verbose "Detected an update conflict, restarting server to allow DSC to resume and retry"
                $global:DSCMachineStatus = 1
            } else {
                throw $_
            }
        }
        
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

        try {
            $result = Invoke-Command @invokeArgs -Verbose
        } catch {
            if ($_.Exception.Message.Contains("An update conflict has occurred, and you must re-try this action")) {
                Write-Verbose "Detected an update conflict, restarting server to allow DSC to resume and retry"
                $global:DSCMachineStatus = 1
            } else {
                throw $_
            }
        }

        if ($session) { Remove-PSSession $session } 
        return $result
    }
}

function Rename-xSharePointParamValue() {
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true,Position=1,ValueFromPipeline=$true)] $params,
        [parameter(Mandatory = $true,Position=2)] $oldName,
        [parameter(Mandatory = $true,Position=3)] $newName
    )

    if ($params.ContainsKey($oldName)) {
        $params.Add($newName, $params.$oldName)
        $params.Remove($oldName) | Out-Null
    }
    return $params
}

function Remove-xSharePointUserToLocalAdmin() {
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true,Position=1)] [string] $UserName
    )

    if ($UserName.Contains("\") -eq $false) {
        throw [Exception] "Usernames should be formatted as domain\username"
    }

    $domainName = $UserName.Split('\')[0]
    $accountName = $UserName.Split('\')[1]

    Write-Verbose -Message "Removing $domainName\$userName from local admin group"
    ([ADSI]"WinNT://$($env:computername)/Administrators,group").Remove("WinNT://$domainName/$accountName") | Out-Null
}

function Test-xSharePointObjectHasProperty() {
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true,Position=1)]  [Object] $Object,
        [parameter(Mandatory = $true,Position=2)]  [String] $PropertyName
    )
    return [bool]($Object.PSobject.Properties.name -contains $PropertyName)
}

function Test-xSharePointSpecificParameters() {
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true,Position=1)]  [HashTable] $CurrentValues,
        [parameter(Mandatory = $true,Position=2)]  [Object]    $DesiredValues,
        [parameter(Mandatory = $false,Position=3)] [Array]     $ValuesToCheck
    )

    $returnValue = $true

    if (($DesiredValues.GetType().Name -ne "HashTable") `
        -and ($DesiredValues.GetType().Name -ne "CimInstance") `
        -and ($DesiredValues.GetType().Name -ne "PSBoundParametersDictionary")) {
        throw "Property 'DesiredValues' in Test-xSharePointSpecificParameters must be either a Hashtable or CimInstance. Type detected was $($DesiredValues.GetType().Name)"
    }

    if (($DesiredValues.GetType().Name -eq "CimInstance") -and ($null -eq $ValuesToCheck)) {
        throw "If 'DesiredValues' is a Hashtable then property 'ValuesToCheck' must contain a value"
    }

    if (($ValuesToCheck -eq $null) -or ($ValuesToCheck.Count -lt 1)) {
        $KeyList = $DesiredValues.Keys
    } else {
        $KeyList = $ValuesToCheck
    }

    $KeyList | ForEach-Object {
        if (($_ -ne "Verbose") -and ($_ -ne "InstallAccount")) {
            if (($CurrentValues.ContainsKey($_) -eq $false) -or ($CurrentValues.$_ -ne $DesiredValues.$_)) {
                if ($DesiredValues.GetType().Name -eq "HashTable" -or $DesiredValues.GetType().Name -eq "PSBoundParametersDictionary") {
                    $CheckDesiredValue = $DesiredValues.ContainsKey($_)
                } else {
                    $CheckDesiredValue = Test-xSharePointObjectHasProperty $DesiredValues $_
                }

                if ($CheckDesiredValue) {
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
                        "Int16" {
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

function Test-xSharePointUserIsLocalAdmin() {
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true,Position=1)] [string] $UserName
    )

    if ($UserName.Contains("\") -eq $false) {
        throw [Exception] "Usernames should be formatted as domain\username"
    }

    $domainName = $UserName.Split('\')[0]
    $accountName = $UserName.Split('\')[1]

    return ([ADSI]"WinNT://$($env:computername)/Administrators,group").PSBase.Invoke("Members") | 
        ForEach-Object {$_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)} | 
        Where-Object { $_ -eq $accountName }
}

function Set-xSharePointObjectPropertyIfValueExists() {
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true,Position=1)] [object] $ObjectToSet,
        [parameter(Mandatory = $true,Position=1)] [string] $PropertyToSet,
        [parameter(Mandatory = $true,Position=1)] [object] $ParamsValue,
        [parameter(Mandatory = $true,Position=1)] [string] $ParamKey
    )

    if ($ParamsValue.GetType().Name -eq "Hashtable") {
        if ($ParamsValue.ContainsKey($ParamKey) -eq $true) {
            $ObjectToSet.$PropertyToSet = $ParamsValue.$ParamKey
        }
    } else {
        if (((Test-xSharePointObjectHasProperty $ParamsValue $ParamKey) -eq $true) -and ($null -ne $ParamsValue.$ParamKey)) {
            $ObjectToSet.$PropertyToSet = $ParamsValue.$ParamKey
        }
    }
}

Export-ModuleMember -Function *
