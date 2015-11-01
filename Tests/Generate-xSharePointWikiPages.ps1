param
(
    [parameter(Mandatory = $true)] [System.String] $OutPutPath
)

Import-Module (Join-Path $PSScriptRoot "xSharePoint\xSharePoint.TestHelpers.psm1")

$repoDir = Join-Path $PSScriptRoot "..\" -Resolve

Get-ChildItem "$repoDir\modules\xSharePoint\**\*.schema.mof" -Recurse | `
    ForEach-Object { 
        Write-Output "Generating wiki page for $($result.FriendlyName)"
        $result = Get-MofSchemaObject $_.FullName

        $output = "**Parameters**" + [Environment]::NewLine + [Environment]::NewLine

        foreach($property in $result.Attributes) {
            $output += " - $($property.Name) ($($property.State), $($property.DataType)"
            if ([string]::IsNullOrEmpty($property.ValueMap) -ne $true) {
                $output += ", Allowed values: "
                $property.ValueMap | ForEach-Object {
                    $output += $_ + ", "
                }
                $output = $output.TrimEnd(" ")
                $output = $output.TrimEnd(",")
            }
            $output += ")" + [Environment]::NewLine
        }

        $output += [Environment]::NewLine + $result.Documentation

        $output | Out-File -FilePath (Join-Path $OutPutPath "$($result.FriendlyName).md") -Encoding utf8 -Force
    }