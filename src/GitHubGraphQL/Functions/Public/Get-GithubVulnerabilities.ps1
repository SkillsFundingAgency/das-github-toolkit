function Get-GithubVulnerabilities {
    [CmdletBinding()]
    param(
        [string]$GitHubOrg,
        [string]$RepoSearchString
    )

    $Baseurl = "https://api.github.com/graphql"
    $SessionInfo = Get-GitHubSessionInformation

    $HasNextPage = $true
    $PageInfo = ""
    $repositories = @()

    while ($HasNextPage) {
        $query = @"
{
    "query": "query { organization(login:\"$GitHubOrg\") { name repositories(first:100$PageInfo){ totalCount pageInfo { endCursor hasNextPage } edges { node { name vulnerabilityAlerts(first:40){ edges { node { securityVulnerability { vulnerableVersionRange  package { name } }  } } }  } } } }  }"
}
"@
        $response = Invoke-RestMethod -Method Post -Uri "$($Baseurl)" -Body $query -Headers $SessionInfo.Headers

        $HasNextPage = $response.data.organization.repositories.pageInfo.hasNextPage -eq "True"
        $PageInfo = ", after:\""$($response.data.organization.repositories.pageInfo.endCursor)\"""
        $repositories += $response.data.organization.repositories.edges
    }

    $VulnerableRepos = $repositories | Where-Object { $_.node.name -like $RepoSearchString -and $_.node.vulnerabilityAlerts.edges.Length -gt 0 }

    ($VulnerableRepos | ForEach-Object {
        return @{
            name = $_.node.name
            alerts = $_.node.vulnerabilityAlerts.edges | ForEach-Object {
                return $_.node.securityVulnerability
            }
        }
    }) | ConvertTo-Json -Depth 10
}
