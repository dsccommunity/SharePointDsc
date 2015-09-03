function Invoke-xSharePointCommand() {
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $Credential,

        [parameter(Mandatory = $false)]
        [System.Collections.Generic.Dictionary`2[System.String,System.Object]]
        $Arguments,

        [parameter(Mandatory = $true)]
        [ScriptBlock]
        $ScriptBlock
    )

    $VerbosePreference = 'Continue'

    $invokeArgs = @{
        ScriptBlock = $ScriptBlock
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

        $result = Invoke-Command @invokeArgs
        return $result
    } else {
        if (-not $Env:USERNAME.Contains("$")) {
            throw [Exception] "Unable to use both InstallAccount and PsDscRunAsCredential in a single resource. Remove one and try again."
            return
        }
        Write-Verbose "Executing using a provided credential and local PSSession as user $($Credential.UserName)"

        #Running garbage collection to resolve issues related to Azure DSC extention use
        [GC]::Collect()

        $session = New-PSSession -ComputerName $env:COMPUTERNAME -Credential $Credential -Authentication CredSSP -Name "Microsoft.SharePoint.DSC" -SessionOption (New-PSSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck -OperationTimeout 0 -IdleTimeout 60000)
        
        $result = Invoke-Command @invokeArgs -Session $session

        Remove-PSSession $session
        return $result
    }
}

function Rename-xSharePointParamValue() {
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true,Position=1)]
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

function Remove-xSharePointNullParamValues() {
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true,Position=1)]
        $Params
    )
    $keys = $Params.Keys
    ForEach ($key in $keys) {
        if ($null -eq $Params.$key) {
            $Params.Remove($key) | Out-Null
        }
    }
    return $Params
}

function Get-xSharePointAssemblyVerion() {
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true,Position=1)]
        $PathToAssembly
    )
    return (Get-Command $PathToAssembly).FileVersionInfo.FileMajorPart
}

Export-ModuleMember -Function *
