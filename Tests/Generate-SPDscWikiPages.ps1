param
(
    [parameter(Mandatory = $true)] [System.String] $OutPutPath
)

Import-Module (Join-Path $PSScriptRoot "SharePointDsc\SharePointDsc.TestHelpers.psm1")

$repoDir = Join-Path $PSScriptRoot "..\" -Resolve

Get-ChildItem "$repoDir\modules\SharePointDsc\**\*.schema.mof" -Recurse | `
    ForEach-Object { 
        $mofFileObject = $_
        $result = (Get-MofSchemaObject $_.FullName) | Where-Object { $_.ClassName -eq $mofFileObject.Name.Replace(".schema.mof", "") -and $null -ne $_.FriendlyName }
        Write-Output "Generating wiki page for $($result.FriendlyName)"
        
        $output = "**Parameters**" + [Environment]::NewLine + [Environment]::NewLine
        $output += "| Parameter | Attribute | DataType | Description | Allowed Values |" + [Environment]::NewLine
        $output += "| --- | --- | --- | --- | --- |" + [Environment]::NewLine
        foreach($property in $result.Attributes) {
            $output += "| **$($property.Name)** | $($property.State) | $($property.DataType) | $($property.Description) | "
            if ([string]::IsNullOrEmpty($property.ValueMap) -ne $true) {
                $property.ValueMap | ForEach-Object {
                    $output += $_ + ", "
                }
                $output = $output.TrimEnd(" ")
                $output = $output.TrimEnd(",")
            }
            $output += "|" + [Environment]::NewLine
        }
        $output += [Environment]::NewLine + $result.Documentation
        $output | Out-File -FilePath (Join-Path $OutPutPath "$($result.FriendlyName).md") -Encoding utf8 -Force
    }