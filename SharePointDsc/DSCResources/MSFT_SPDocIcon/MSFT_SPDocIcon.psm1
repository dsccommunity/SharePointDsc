$dociconPath = Join-Path -Path $env:CommonProgramFiles -ChildPath 'microsoft shared\Web Server Extensions\{0}\TEMPLATE\XML'
$iconPath = Join-Path -Path $env:CommonProgramFiles -ChildPath 'microsoft shared\Web Server Extensions\{0}\TEMPLATE\IMAGES'

$dociconFileName = 'DOCICON.XML'

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateScript( { $_ -match "^\w*$" })]
        [String]
        $FileType,

        [Parameter()]
        [String]
        $IconFile,

        [Parameter()]
        [String]
        $EditText,

        [Parameter()]
        [String]
        $OpenControl,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting status of $FileType in 'docicon.xml'"

    $nullReturn = @{
        FileType    = $FileType
        IconFile    = $null
        EditText    = $null
        OpenControl = $null
        Ensure      = "Absent"
    }

    if ($Ensure -eq "Present" -and $PSBoundParameters.ContainsKey('IconFile') -eq $false)
    {
        Write-Verbose -Message "When Ensure=Present, please also specify the IconFile parameter."
        return $nullReturn
    }

    $dociconPath = $dociconPath -f (Get-SPDscInstalledProductVersion).FileMajorPart
    $docIconFilePath = Join-Path -Path $dociconPath -ChildPath $dociconFileName

    if ((Test-Path -Path $docIconFilePath) -eq $false)
    {
        Write-Verbose -Message "Docicon.xml file is not found: $docIconFilePath"
        return $nullReturn
    }

    $xmlDoc = New-Object -TypeName 'System.Xml.XmlDocument'
    $xmlDoc.Load($docIconFilePath)
    $xmlNode = $xmlDoc.SelectSingleNode("//Mapping[@Key='$($FileType.ToLower())']")

    if ($null -eq $xmlNode)
    {
        Write-Verbose -Message "Specifed file type ($FileType) does not exist in docicon.xml"
        return $nullReturn
    }
    else
    {
        Write-Verbose -Message "Specifed file type ($FileType) exists in docicon.xml"

        $iconPath = $iconPath -f (Get-SPDscInstalledProductVersion).FileMajorPart
        $iconFilePath = Join-Path -Path $iconPath -ChildPath $xmlNode.Value
        if (Test-Path -Path $iconFilePath)
        {
            Write-Verbose -Message "Icon file exists: $iconFilePath"
            return @{
                FileType    = $xmlNode.Key
                IconFile    = $xmlNode.Value
                EditText    = $xmlNode.EditText
                OpenControl = $xmlNode.OpenControl
                Ensure      = "Present"
            }
        }
        else
        {
            Write-Verbose -Message "Icon file does not exist: $iconFilePath"
            return $nullReturn
        }
    }
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateScript( { $_ -match "^\w*$" })]
        [String]
        $FileType,

        [Parameter()]
        [String]
        $IconFile,

        [Parameter()]
        [String]
        $EditText,

        [Parameter()]
        [String]
        $OpenControl,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting status of $FileType in 'docicon.xml'"

    if ($Ensure -eq "Present" -and $PSBoundParameters.ContainsKey('IconFile') -eq $false)
    {
        $message = "When Ensure=Present, please also specify the IconFile parameter."
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    if ($Ensure -eq "Present" -and (Test-Path -Path $IconFile) -eq $false)
    {
        $message = "Specified IconFile does not exist: $IconFile"
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    $dociconPath = $dociconPath -f (Get-SPDscInstalledProductVersion).FileMajorPart
    $docIconFilePath = Join-Path -Path $dociconPath -ChildPath $dociconFileName

    if ((Test-Path -Path $docIconFilePath) -eq $false)
    {
        $message = "Docicon.xml file is not found: $docIconFilePath"
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    $xmlDoc = New-Object -TypeName 'System.Xml.XmlDocument'
    $xmlDoc.Load($docIconFilePath)
    $xmlNode = $xmlDoc.SelectSingleNode("//Mapping[@Key='$($FileType.ToLower())']")

    $iconPath = $iconPath -f (Get-SPDscInstalledProductVersion).FileMajorPart

    $changed = $false
    if ($Ensure -eq 'Present')
    {
        $iconFileName = Split-Path -Path $IconFile -Leaf
        $targetIconFile = Join-Path -Path $iconPath -ChildPath $iconFileName

        if ((Test-Path -Path $targetIconFile) -eq $false)
        {
            Write-Verbose -Message "Copying the IconFile to the server: $iconFileName"
            $null = Copy-Item -Path $IconFile -Destination $iconPath -Force
        }
        else
        {
            Write-Verbose -Message "IconFile already exists on the server: $iconFileName"
            $sourceHash = (Get-FileHash -Path $IconFile -Algorithm SHA512).Hash
            $targetHash = (Get-FileHash -Path $targetIconFile -Algorithm SHA512).Hash
            if ($sourceHash -ne $targetHash)
            {
                Write-Verbose -Message "Files differ. Updating the IconFile on the server: $iconFileName"
                $null = Copy-Item -Path $IconFile -Destination $iconPath -Force
            }
        }

        if ($null -eq $xmlNode)
        {
            Write-Verbose -Message "Adding $FileType to docicon.xml"

            $xmlNode = $xmlDoc.CreateElement("Mapping")
            $xmlNode.SetAttribute("Key", $FileType)

            $xmlNode.SetAttribute("Value", $iconFileName)

            if ([System.String]::IsNullOrEmpty($EditText) -eq $false)
            {
                $xmlNode.SetAttribute("EditText", $EditText)
            }

            if ([System.String]::IsNullOrEmpty($OpenControl) -eq $false)
            {
                $xmlNode.SetAttribute("OpenControl", $OpenControl)
            }

            $xmlDoc.DocIcons.ByExtension.AppendChild($xmlNode) | Out-Null
            $changed = $true
        }
        else
        {
            Write-Verbose -Message "Updating $FileType in docicon.xml"
            if ($xmlNode.Value -ne $iconFileName)
            {
                Write-Verbose -Message "  Updating IconFile parameter"
                $xmlNode.SetAttribute("Value", $iconFileName)
                $changed = $true
            }

            if ($PSBoundParameters.ContainsKey('EditText') -and `
                    $xmlNode.EditText -ne $EditText)
            {
                Write-Verbose -Message "  Updating EditText parameter"
                $xmlNode.SetAttribute("EditText", $EditText)
                $changed = $true
            }

            if ($PSBoundParameters.ContainsKey('OpenControl') -and `
                    $xmlNode.OpenControl -ne $OpenControl)
            {
                Write-Verbose -Message "  Updating OpenControl parameter"
                $xmlNode.SetAttribute("OpenControl", $OpenControl)
                $changed = $true
            }
        }
    }
    else
    {
        if ($null -ne $xmlNode)
        {
            Write-Verbose -Message "Removing $FileType from docicon.xml"
            $targetIconFile = Join-Path -Path $iconPath -ChildPath $xmlNode.Value

            if (Test-Path -Path $targetIconFile)
            {
                Remove-Item -Path $targetIconFile -Force -Confirm:$false
            }

            $xmlDoc.DocIcons.ByExtension.RemoveChild($xmlNode) | Out-Null
            $changed = $true
        }
    }

    if ($changed -eq $true)
    {
        Write-Verbose -Message "Saving changes to Docicon.xml file"
        $xmlDoc.Save($DocIconFilePath)
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateScript( { $_ -match "^\w*$" })]
        [String]
        $FileType,

        [Parameter()]
        [String]
        $IconFile,

        [Parameter()]
        [String]
        $EditText,

        [Parameter()]
        [String]
        $OpenControl,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing status of $FileType in 'docicon.xml'"

    $PSBoundParameters.Ensure = $Ensure

    $CurrentValues = Get-TargetResource @PSBoundParameters

    if ($PSBoundParameters.ContainsKey('IconFile'))
    {
        Write-Verbose "Stripping the path from IconFile to simplify parameter comparison"
        $PSBoundParameters.IconFile = Split-Path -Path $PSBoundParameters.IconFile -Leaf
    }

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
        -Source $($MyInvocation.MyCommand.Source) `
        -DesiredValues $PSBoundParameters `
        -ValuesToCheck @(
        "FileType",
        "IconFile",
        "EditText",
        "OpenControl",
        "Ensure"
    )

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

function Export-TargetResource
{
    $VerbosePreference = "SilentlyContinue"
    $ParentModuleBase = Get-Module "SharePointDsc" -ListAvailable | Select-Object -ExpandProperty Modulebase
    $module = Join-Path -Path $ParentModuleBase -ChildPath "\DSCResources\MSFT_SPDocIcon\MSFT_SPDocIcon.psm1" -Resolve

    $Content = ''
    $params = Get-DSCFakeParameters -ModulePath $module

    $dociconPath = $dociconPath -f (Get-SPDscInstalledProductVersion).FileMajorPart
    $docIconFilePath = Join-Path -Path $dociconPath -ChildPath $dociconFileName

    if ((Test-Path -Path $docIconFilePath) -eq $false)
    {
        $message = "Docicon.xml file is not found: $docIconFilePath"
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    $xmlDoc = New-Object -TypeName 'System.Xml.XmlDocument'
    $xmlDoc.Load($docIconFilePath)

    $dociconSourcePath = "C:\Install\Icons"
    foreach ($mapping in $xmlDoc.DocIcons.ByExtension.Mapping)
    {
        $PartialContent = "        SPDocIcon DocIcon" + $mapping.Key + "`r`n"
        $PartialContent += "        {`r`n"
        $params.FileType = $mapping.Key
        $params.Ensure = "Present"
        $results = Get-TargetResource @params

        $results = Repair-Credentials -results $results

        # Parameterize IconFile parameter
        Add-ConfigurationDataEntry -Node "NonNodeData" `
            -Key "DocIcon$($mapping.Key)" `
            -Value (Join-Path -Path $dociconSourcePath -ChildPath $results.IconFile) `
            -Description "Path to the icon file of the file type;"
        $results.IconFile = "`$ConfigurationData.NonNodeData.DocIcon$($mapping.Key)"

        $currentBlock = Get-DSCBlock -Params $results -ModulePath $module
        $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "PsDscRunAsCredential"

        $PartialContent += $currentBlock
        $PartialContent += "        }`r`n"
        $Content += $PartialContent
    }

    return $Content
}

Export-ModuleMember -Function *-TargetResource
