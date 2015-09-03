function Get-xSharePointAuthenticatedPSSession() {
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true,Position=1)]
        [System.Management.Automation.PSCredential]
        $Credential
    )

    #Running garbage collection to resolve issues related to Azure DSC extention use
    [GC]::Collect()

    Write-Verbose -Message "Creating new PowerShell session"
    $session = New-PSSession -ComputerName $env:COMPUTERNAME -Credential $Credential -Authentication CredSSP -Name "Microsoft.SharePoint.DSC" -SessionOption (New-PSSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck -OperationTimeout 0 -IdleTimeout 60000)
    Invoke-Command -Session $session -ScriptBlock {
        if ($null -eq (Get-PSSnapin -Name "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue)) 
        {
            Add-PSSnapin -Name "Microsoft.SharePoint.PowerShell"
        }
        $VerbosePreference = 'Continue'
    }
    return $session 
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
    return (Get-Command $PathToAssembly).Version
}

Export-ModuleMember -Function *
