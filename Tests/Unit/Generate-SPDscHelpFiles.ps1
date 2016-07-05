param
(
    [parameter(Mandatory = $true)] [System.String] $OutPutPath
)

Import-Module (Join-Path $PSScriptRoot "SharePointDSC\SharePointDSC.TestHelpers.psm1")

$repoDir = Join-Path $PSScriptRoot "..\..\" -Resolve

Get-ChildItem "$repoDir\modules\SharePointDSC\**\*.schema.mof" -Recurse | `
    ForEach-Object {
        $mofFileObject = $_ 
        $result = (Get-MofSchemaObject $_.FullName) | Where-Object { $_.ClassName -eq $mofFileObject.Name.Replace(".schema.mof", "") -and $null -ne $_.FriendlyName  }
        if ($null -ne $result) {
            Write-Output "Generating help document for $($result.FriendlyName)"
        
            $output = ".NAME" + [Environment]::NewLine
            $output += "    $($result.FriendlyName)" + [Environment]::NewLine + [Environment]::NewLine

            $output += $result.Documentation.Replace("**Description**", ".SYNOPSIS").Replace("**Example**",".EXAMPLE") + [Environment]::NewLine

            foreach($property in $result.Attributes) {
                
                $output += ".PARAMETER $($property.Name)" + [Environment]::NewLine
                $output += "    $($property.State) - $($property.DataType)" + [Environment]::NewLine
                
                if ([string]::IsNullOrEmpty($property.ValueMap) -ne $true) {
                    $output += "    Allowed values: "
                    $property.ValueMap | ForEach-Object {
                        $output += $_ + ", "
                    }
                    $output = $output.TrimEnd(" ")
                    $output = $output.TrimEnd(",")
                    $output +=  [Environment]::NewLine
                }
                $output += "    " + $property.Description + [Environment]::NewLine + [Environment]::NewLine
            }

            $output | Out-File -FilePath (Join-Path $OutPutPath "about_$($result.FriendlyName).help.txt") -Encoding utf8 -Force
        }
    }