<#

.SYNOPSIS
Gets all active pull requests for specified repository

.DESCRIPTION
Gets all active pull requests for specified repository

.PARAMETER GitHubOrganisation
The GitHub organisation

.PARAMETER RepositoryName
The repository of the GitHub organisation

.EXAMPLE
Set-GitHubSessionInformation -PatToken <not-a-real-pat-token>
Get-GitHubRepoPullRequest -GitHubOrganisation MyOrganisation -RepositoryName MyRepository

.NOTES
The documentation for the GitHub endpoint used by this function can be found here:
https://docs.github.com/en/rest/pulls/pulls#list-pull-requests

#>
function Get-GitHubRepoPullRequest {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
    param(
        [Parameter(Mandatory = $true)]
        [String]$GitHubOrganisation,
        [Parameter(Mandatory = $true)]
        [String]$RepositoryName
    )

    $PullRequests = Invoke-GitHubRestMethod -Method GET -Uri "/repos/$GitHubOrganisation/$RepositoryName/pulls"

    return $PullRequests
}
