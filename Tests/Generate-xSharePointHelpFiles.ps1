param
(
    [parameter(Mandatory = $true)] [System.String] $OutPutPath
)

Import-Module (Join-Path $PSScriptRoot "xSharePoint\xSharePoint.TestHelpers.psm1")

$repoDir = Join-Path $PSScriptRoot "..\" -Resolve

Get-ChildItem "$repoDir\modules\xSharePoint\**\*.schema.mof" -Recurse | `
    ForEach-Object { 
        $result = (Get-MofSchemaObject $_.FullName) | Where-Object { $_.ClassName -eq $_.Name.Replace(".schema.mof", "") }
        Write-Output "Generating help document for $($result.FriendlyName)"
        
        $output = "NAME" + [Environment]::NewLine
        $output += "    $($result.FriendlyName)" + [Environment]::NewLine + [Environment]::NewLine
        $output += "PARAMETERS" + [Environment]::NewLine

        foreach($property in $result.Attributes) {
            $output += "    $($property.Name) ($($property.State), $($property.DataType)"
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

        $output += [Environment]::NewLine + $result.Documentation.Replace("**Description**", "DESCRIPTION").Replace("**Example**","EXAMPLE")

        $output | Out-File -FilePath (Join-Path $OutPutPath "about_$($result.FriendlyName).help.txt") -Encoding utf8 -Force
    }