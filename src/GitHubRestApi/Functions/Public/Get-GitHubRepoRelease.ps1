<#

.SYNOPSIS
Gets the GitHub releases of a specified repository

.DESCRIPTION
Gets the GitHub releases of a specified repository

.PARAMETER GitHubOrganisation
The GitHub organisation

.PARAMETER RepositoryName
The repository of the GitHub organisation

.EXAMPLE
Set-GitHubSessionInformation -PatToken <not-a-real-pat-token>
Get-GitHubRepoRelease -GitHubOrganisation MyOrganisation -RepositoryName MyRepository

.NOTES
The documentation for the GitHub endpoint used by this function can be found here:
https://docs.github.com/en/rest/releases/releases#list-releases

#>
function Get-GitHubRepoRelease {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]$GitHubOrganisation,
        [Parameter(Mandatory = $true)]
        [String]$RepositoryName
    )

    $Releases = Invoke-GithubRestMethod -Method GET -Uri "/repos/$GitHubOrganisation/$RepositoryName/releases"

    return $Releases
}

