<#

.SYNOPSIS
Gets a single reference from the Git database for a specified repository branch

.DESCRIPTION
Gets a single reference from the Git database for a specified repository branch

.PARAMETER GitHubOrganisation
The GitHub organisation

.PARAMETER RepositoryName
The repository of the GitHub organisation

.PARAMETER BranchName
The branch of the repository to search

.EXAMPLE
Set-GitHubSessionInformation -PatToken <not-a-real-pat-token>
Get-GitHubRepoBranchRef -GitHubOrganisation MyOrganisation -RepositoryName MyRepository -BranchName MyBranch

.NOTES
The documentation for the GitHub endpoint used by this function can be found here:
https://docs.github.com/en/rest/git/refs#get-a-reference

#>
function Get-GithubRepoBranchRef
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]$GitHubOrganisation,
        [Parameter(Mandatory = $true)]
        [String]$RepositoryName,
        [Parameter(Mandatory = $true)]
        [String]$BranchName
    )

    $BranchRef = Invoke-GithubRestMethod -Method GET -Uri "/repos/$GitHubOrganisation/$RepositoryName/git/ref/heads/$BranchName"

    return $BranchRef
}
