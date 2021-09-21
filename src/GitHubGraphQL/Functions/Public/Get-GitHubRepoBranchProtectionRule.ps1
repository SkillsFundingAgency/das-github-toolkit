<#
.SYNOPSIS
Retrieves the Branch Protection rules for a GitHub repo(s) and returns some of it's properties

.DESCRIPTION
Retrieves the Branch Protection rules for a GitHub repo(s) and returns some of it's properties

.PARAMETER GitHubOrg
The name of the GitHub organisation

.EXAMPLE
Set-GitHubSessionInformation -PatToken <not-a-real-pat-token>
Get-GitHubRepoBranchProtectionRule -GitHubOrg MyGitHubOrg
#>
function Get-GitHubRepoBranchProtectionRule {
    [CmdletBinding()]
    param(
        [string]$GitHubOrg
    )

    $Baseurl = "https://api.github.com/graphql"
    $SessionInfo = Get-GitHubSessionInformation

    $HasNextPage = $true
    $PageInfo = ""
    $Rules = @()

    while ($HasNextPage) {
        $BranchQuery = @"
{
    "query": "query { organization(login: \"$GitHubOrg\") { repositories(first: 100$PageInfo) { nodes { branchProtectionRules(first: 10) { nodes { requiresCodeOwnerReviews requiresStrictStatusChecks requiresStatusChecks requiresApprovingReviews requiredApprovingReviewCount matchingRefs(first: 10) { nodes { name } } } } name isArchived } pageInfo { hasNextPage endCursor } totalCount } } }"
}
"@
        $Response = Invoke-RestMethod -Method POST -Uri "$($Baseurl)" -Body $BranchQuery -Headers $SessionInfo.Headers

        $HasNextPage = $Response.data.organization.repositories.pageInfo.hasNextPage -eq "True"
        $PageInfo = ", after:\""$($Response.data.organization.repositories.pageInfo.endCursor)\"""
        $Rules += $Response.data.organization.repositories.nodes
    }

    $Rules | ForEach-Object {
        return @{
            repoName  = $_.name
            repoBranchProtectionRules = $_.branchProtectionRules.nodes | ForEach-Object {
                return [PSCustomObject]@{
                    branchName = $_.matchingRefs.nodes.name
                    requiresStrictStatusChecks       = $_.requiresStrictStatusChecks
                    requiresStatusChecks = $_.requiresStatusChecks
                    requiresApprovingReviews = $_.requiresApprovingReviews
                    requiredApprovingReviewCount = $_.requiredApprovingReviewCount
                }
            }
        }
    }
}
