[CmdletBinding()]
param()

$ClassPaths = @(
    "$($PSScriptRoot)\GitHubAudit\Classes\*.ps1"
    "$($PSScriptRoot)\GitHubTools\Classes\*.ps1"
)

$FunctionPaths = @(
    "$PSScriptRoot\GitHubCore\Functions\Public\*.ps1",
    "$PSScriptRoot\GitHubGraphQL\Functions\Public\*.ps1",
    "$PSScriptRoot\GitHubRestApi\Functions\Public\*.ps1",
    "$PSScriptRoot\GitHubAudit\Functions\Public\*.ps1",
    "$PSScriptRoot\GitHubRepoManager\Functions\Public\*.ps1",
    "$PSScriptRoot\GitHubTools\Functions\Public\*.ps1"
)

$Classes = @()
foreach ($Path in $ClassPaths) {
    $Classes += Get-ChildItem -Path $Path -Exclude $PSCmdlet.MyInvocation.MyCommand
}

foreach($Class in $Classes) {

    try {

        . $Class.FullName

    }
    catch [System.Management.Automation.ParseException] {

        $MissingClasses = (Select-String -InputObject $_.Exception.ToString() -Pattern "Unable to find type \[(\w*)\]" -AllMatches).Matches | Select-Object -ExpandProperty Value
        foreach ($MissingClass in $MissingClasses) {

            $MissingClassName = $MissingClass -replace '(Unable to find type \[)(.*)(\])', '$2'
            $MissingClassFile = Get-Item -Path "$($Class.Directory)\$($MissingClassName).ps1"
            try {

                . $MissingClassFile.FullName
                . $Class.FullName

            }
            catch {

                Write-Warning "Failed to load class $($Class.FullName)"

            }

        }

    }
    catch {

        throw "Failed to import function $($Class.FullName)"

    }

}

$Scripts = @()
foreach ($Path in $FunctionPaths) {
    $Scripts += Get-ChildItem -Path $Path -Exclude $PSCmdlet.MyInvocation.MyCommand
}

foreach($Function in $Scripts) {

    try {

        Write-Verbose "Importing $($Function.FullName)"
        . $Function.FullName

    }
    catch {

        Write-Error "Failed to import function $($Function.FullName)"

    }

}

return $Scripts
