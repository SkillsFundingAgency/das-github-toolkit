<#

.SYNOPSIS
Creates a new pull request on a specified repository with a specified origin and target branch

.DESCRIPTION
Creates a new pull request on a specified repository with a specified origin and target branch

.PARAMETER GitHubOrganisation
The GitHub organisation

.PARAMETER RepositoryName
The repository of the GitHub organisation

.PARAMETER BaseRefSha
The commit SHA-1 hash that the new branch is based from

.PARAMETER NewBranchName
The name of the new branch being created


.EXAMPLE
Set-GitHubSessionInformation -PatToken <not-a-real-pat-token>
New-GitHubRepoBranch -GitHubOrganisation MyOrganisation -RepositoryName MyRepository -BaseRefSha bf493c4131ac993627ca902aa5b88953690ee833 -NewBranchName MyNewBranch

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
