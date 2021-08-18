function Get-GitHubRepos {
    [CmdletBinding()]
    param(
        [string]$GitHubOrg
    )
    $Baseurl = "https://api.github.com/graphql"
    $SessionInfo = Get-GitHubSessionInformation

    $HasNextPage = $true
    $PageInfo = ""
    $Repositories = @()

    while ($HasNextPage) {
        $BranchQuery = @"
{
    "query": "query { organization(login: \"$GitHubOrg\") { repositories(first: 100$PageInfo) { nodes { name isArchived isPrivate } pageInfo { endCursor hasNextPage } } } }"
}
"@

        Write-Verbose "Retrieving page ..."
        $Response = Invoke-RestMethod -Method POST -Uri "$($Baseurl)" -Body $BranchQuery -Headers $SessionInfo.Headers
        $HasNextPage = $Response.data.organization.repositories.pageInfo.hasNextPage -eq "True"
        $PageInfo = ", after:\""$($Response.data.organization.repositories.pageInfo.endCursor)\"""
        $Repositories += $Response.data.organization.repositories.nodes
    }

    $Repositories
}
