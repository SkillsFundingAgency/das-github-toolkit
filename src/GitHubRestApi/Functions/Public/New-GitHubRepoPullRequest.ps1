<#

.SYNOPSIS
Creates a new pull request on a specified repository with a specified origin and target branch

.DESCRIPTION
Creates a new pull request on a specified repository with a specified origin and target branch

.PARAMETER GitHubOrganisation
The GitHub organisation

.PARAMETER RepositoryName
The repository of the GitHub organisation

.PARAMETER OriginBranchName
The name of the branch that is to be merged into the tagert branch

.PARAMETER TargetBranchName
The name of the branch that is being merged into, typically main or master

.PARAMETER Title
The title of the pull request that will be created

.EXAMPLE
Set-GitHubSessionInformation -PatToken <not-a-real-pat-token>
New-GitHubRepoBranch -GitHubOrganisation MyOrganisation -RepositoryName MyRepository -OriginBranchName new-feature-x -TargetBranchName main -Title "Add new feature x"

.NOTES
The documentation for the GitHub endpoint used by this function can be found here:
https://docs.github.com/en/rest/pulls/pulls#create-a-pull-request

#>
function New-GitHubRepoPullRequest {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
    param(
        [Parameter(Mandatory = $true)]
        [String]$GitHubOrganisation,
        [Parameter(Mandatory = $true)]
        [String]$RepositoryName,
        [Parameter(Mandatory = $true)]
        [String]$OriginBranchName,
        [Parameter(Mandatory = $true)]
        [String]$TargetBranchName,
        [Parameter(Mandatory = $true)]
        [String]$Title
    )

    $CreatePullRequestParams = @{
        title = $Title
        head = $OriginBranchName
        base = $TargetBranchName
    }
    $PullRequest = Invoke-GitHubRestMethod -Method POST -Uri "/repos/$GitHubOrganisation/$RepositoryName/pulls" -Body ($CreatePullRequestParams | ConvertTo-Json)

    return $PullRequest
}
