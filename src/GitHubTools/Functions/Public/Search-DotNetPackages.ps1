<#
.SYNOPSIS
Searches for references to a package in files across a GitHub organisation

.DESCRIPTION
Searches for references to a package in files across a GitHub organisation. Searches for the PackageName within files where the PackageName is prefixed with "PackageReference Include ".
Parses the version number from a variety of different file formats. Returns a warning where the file cannot be retrieved or the version cannot be parsed.

.PARAMETER GitHubOrganisation
The GitHub organisation to search

.PARAMETER PackageName
The package to search for

.NOTES
To search private repositories using the V3 REST API you will need 'repo', ie full control permissions over repos.

.EXAMPLE
Set-GitHubSessionInformation -PatToken <not-a-real-pat-token>
Search-DotNetPackages -PackageName Microsoft.Extensions.Configuration -GitHubOrganisation MyOrganisation
#>
function Search-DotNetPackages {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [String]$PackageName,
        [Parameter(Mandatory=$false)]
        [String]$GitHubOrganisation = "SkillsFundingAgency"
    )

    $SearchResults = @()
    $Files = Invoke-GitHubRestMethod -Method GET $('/search/code?q=org%3A' + $GitHubOrganisation + '+PackageReference+Include%3D"' + $PackageName + '"')
    if (!$Files.total_count) {
        throw $Files
    }

    foreach ($File in $Files.items) {
        try {
            $FileContentHeader = @{ Accept = "application/vnd.github.v3.raw" }
            $FileContent = Invoke-GitHubRestMethod -Method GET -Uri "/repos/$GitHubOrganisation/$($File.repository.name)/contents/$($File.path)" -Headers $FileContentHeader
        }
        catch [System.Net.Http.HttpRequestException]{
            Write-Warning "$($_.Exception.Response.StatusCode) $FileUri"
            continue
        }
        catch {
            throw $_
        }

        Remove-Variable -Name Matches -ErrorAction SilentlyContinue
        $Pattern = "<PackageReference Include=`"$PackageName`" Version=`"(.*)`" />"
        if(!($FileContent -match $Pattern)) {
            $Pattern = "<HintPath>\.\.\\packages\\$PackageName\.([\d\.]*)"
            if(!($FileContent -match $Pattern)) {
                $Pattern = "<PackageReference Include=`"$PackageName`">\n[\s]*<Version>(.*)</Version>"
                $null = $FileContent -match $Pattern
            }
        }
        if ($Matches) {
            $SearchResult = New-Object -TypeName GitHubPackageSearch -Property @{
                Repository = $File.repository.name
                PackageName = $PackageName
                Version = $Matches[1]
                ConfigFilePath = $File.path
            }
            $SearchResults += $SearchResult
        }
        else {
            Write-Warning "Package $PackageName not matched in file $($File.path) in repository $($File.repository.name)"
        }
    }

    $SearchResults
}
