function Add-SPDSCUserToLocalAdmin() {
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

function Get-SPDscOSVersion {
    [CmdletBinding()]
    param()
    return [System.Environment]::OSVersion.Version
}

function Get-SPDSCAssemblyVersion() {
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true,Position=1)]
        [string]
        $PathToAssembly
    )
    return (Get-Command $PathToAssembly).FileVersionInfo.FileMajorPart
}

function Get-SPDSCServiceContext {
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true,Position=1)]
        $ProxyGroup
    )
      Write-Verbose "Getting SPContext for Proxy group $($proxyGroup)"
    return [Microsoft.SharePoint.SPServiceContext]::GetContext($proxyGroup,[Microsoft.SharePoint.SPSiteSubscriptionIdentifier]::Default)
}

function Get-SPDSCContentService() {
    [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint") | Out-Null
    return [Microsoft.SharePoint.Administration.SPWebService]::ContentService
}


function Get-SPDSCUserProfileSubTypeManager {
    [CmdletBinding()]
    param
    (
        $Context
    )
    [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint") | Out-Null
    
    return [Microsoft.Office.Server.UserProfiles.ProfileSubtypeManager]::Get($Context)
}

function Get-SPDSCInstalledProductVersion() {
    $pathToSearch = "C:\Program Files\Common Files\microsoft shared\Web Server Extensions\*\ISAPI\Microsoft.SharePoint.dll"
    $fullPath = Get-Item $pathToSearch | Sort-Object { $_.Directory } -Descending | Select-Object -First 1
    return (Get-Command $fullPath).FileVersionInfo
}

function Invoke-SPDSCCommand() {
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

function Rename-SPDSCParamValue() {
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true,Position=1,ValueFromPipeline=$true)] $Params,
        [parameter(Mandatory = $true,Position=2)] $OldName,
        [parameter(Mandatory = $true,Position=3)] $NewName
    )

    if ($Params.ContainsKey($OldName)) {
        $Params.Add($NewName, $Params.$OldName)
        $Params.Remove($OldName) | Out-Null
    }
    return $Params
}

function Remove-SPDSCUserToLocalAdmin() {
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

function Resolve-SPDscSecurityIdentifier() {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $SID
    )
    $memberName = ([wmi]"Win32_SID.SID='$SID'").AccountName
    $memberName = "$($env:USERDOMAIN)\$memberName"
    return $memberName
}

function Test-SPDSCObjectHasProperty() {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true,Position=1)]  [Object] $Object,
        [parameter(Mandatory = $true,Position=2)]  [String] $PropertyName
    )
    if (([bool]($Object.PSobject.Properties.name -contains $PropertyName)) -eq $true) {
        if ($Object.$PropertyName -ne $null) {
            return $true
        }
    }
    return $false
}

function Test-SPDSCRunAsCredential() {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $Credential
    )

    # If no specific credential is passed and it's not the machine account, it must be PsDscRunAsCredential
    if (($null -eq $Credential) -and ($Env:USERNAME.Contains("$") -eq $false)) { return $true }
    # return false for all other scenarios
    return $false
}

function Test-SPDSCRunningAsFarmAccount() {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param ( 
        [parameter(Mandatory = $false)] [pscredential] $InstallAccount
    )

    if ($null -eq $InstallAccount) {
        if ($Env:USERNAME.Contains("$")) {
            throw [Exception] "You need to specify a value for either InstallAccount or PsDscRunAsCredential."
            return
        }
        $Username = "$($Env:USERDOMAIN)\$($Env:USERNAME)"
    } else {
        $Username = $InstallAccount.UserName
    }

    $result = Invoke-SPDSCCommand -Credential $InstallAccount -ScriptBlock {
        try {
            $spFarm = Get-SPFarm
        } catch {
            Write-Verbose -Message "Unable to detect local farm."
            return $null
        }
        return $spFarm.DefaultServiceAccount.Name
    }
    
    if ($Username -eq $result) {
        return $true
    }
    return $false
}

function Test-SPDSCSpecificParameters() {
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
        throw "Property 'DesiredValues' in Test-SPDSCSpecificParameters must be either a Hashtable or CimInstance. Type detected was $($DesiredValues.GetType().Name)"
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
            if (($CurrentValues.ContainsKey($_) -eq $false) -or ($CurrentValues.$_ -ne $DesiredValues.$_) -or (($DesiredValues.ContainsKey($_) -eq $true) -and ($DesiredValues.$_.GetType().IsArray))) {
                if ($DesiredValues.GetType().Name -eq "HashTable" -or `
                    $DesiredValues.GetType().Name -eq "PSBoundParametersDictionary") {
                    
                    $CheckDesiredValue = $DesiredValues.ContainsKey($_)
                } else {
                    $CheckDesiredValue = Test-SPDSCObjectHasProperty $DesiredValues $_
                }

                if ($CheckDesiredValue) {
                    $desiredType = $DesiredValues.$_.GetType()
                    $fieldName = $_
                    if ($desiredType.IsArray -eq $true) {
                        if (($CurrentValues.ContainsKey($fieldName) -eq $false) -or ($CurrentValues.$fieldName -eq $null)) {
                            $returnValue = $false
                        } else {
                            if ((Compare-Object -ReferenceObject $CurrentValues.$fieldName -DifferenceObject $DesiredValues.$fieldName) -ne $null) {
                                $returnValue = $false
                            }
                        }
                        
                    } else {
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
    }
    return $returnValue
}

function Test-SPDSCUserIsLocalAdmin() {
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

function Test-SPDSCIsADUser() {
    [OutputType([System.Boolean])]
    [CmdletBinding()]
    param (
        [string] $IdentityName
    )

    if ($IdentityName -like "*\*") {
        $IdentityName = $IdentityName.Substring($IdentityName.IndexOf('\') + 1)
    }

    $searcher = New-Object System.DirectoryServices.DirectorySearcher
    $searcher.filter = "((samAccountName=$IdentityName))"
    $searcher.SearchScope = "subtree"
    $searcher.PropertiesToLoad.Add("objectClass") | Out-Null
    $searcher.PropertiesToLoad.Add("objectCategory") | Out-Null
    $searcher.PropertiesToLoad.Add("name") | Out-Null
    $result = $searcher.FindOne()

    if ($null -eq $result) {
        throw "Unable to locate identity '$IdentityName' in the current domain."
    }

    if ($result[0].Properties.objectclass -contains "user") {
        return $true
    } else {
        return $false
    }
}

function Set-SPDSCObjectPropertyIfValueExists() {
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true,Position=1)] [object] $ObjectToSet,
        [parameter(Mandatory = $true,Position=1)] [string] $PropertyToSet,
        [parameter(Mandatory = $true,Position=1)] [object] $ParamsValue,
        [parameter(Mandatory = $true,Position=1)] [string] $ParamKey
    )
    if ($ParamsValue.PSobject.Methods.name -contains "ContainsKey") {
        if ($ParamsValue.ContainsKey($ParamKey) -eq $true) {
            $ObjectToSet.$PropertyToSet = $ParamsValue.$ParamKey
        }
    } else {
        if (((Test-SPDSCObjectHasProperty $ParamsValue $ParamKey) -eq $true) -and ($null -ne $ParamsValue.$ParamKey)) {
            $ObjectToSet.$PropertyToSet = $ParamsValue.$ParamKey
        }
    }
}

function Remove-SPDSCGenericObject() {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)] 
        [Object] 
        $SourceCollection,

        [parameter(Mandatory = $true)] 
        [Object] 
        $Target
    )
    $SourceCollection.Remove($Target)
}

Export-ModuleMember -Function *
