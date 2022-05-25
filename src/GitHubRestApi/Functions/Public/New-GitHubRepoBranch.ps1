<#

.SYNOPSIS
Creates a new branch on a specified repository from a specified commit SHA-1 hash

.DESCRIPTION
Creates a new branch on a specified repository from a specified commit SHA-1 hash

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
https://docs.github.com/en/rest/git/refs#create-a-reference

#>
function New-GitHubRepoBranch {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
    param(
        [Parameter(Mandatory = $true)]
        [String]$GitHubOrganisation,
        [Parameter(Mandatory = $true)]
        [String]$RepositoryName,
        [Parameter(Mandatory = $true)]
        [String]$BaseRefSha,
        [Parameter(Mandatory = $true)]
        [String]$NewBranchName
    )

    $CreateBranchParams = @{
        ref = "refs/heads/$NewBranchName"
        sha = $BaseRefSha
    }
    Invoke-GitHubRestMethod -Method POST -Uri "/repos/$GitHubOrganisation/$RepositoryName/git/refs" -Body ($CreateBranchParams | ConvertTo-Json)
}
