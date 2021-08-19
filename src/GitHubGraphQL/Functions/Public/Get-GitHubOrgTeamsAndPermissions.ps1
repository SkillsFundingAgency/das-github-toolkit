<#
.SYNOPSIS
Gets the permissions by team that have been applied to a GitHub repo(s) in a single organisation

.DESCRIPTION
Retrieves the teams associated with a GitHub organisation and retrieves the permissions that team has on any repo(s) matching the RepoSearchString

.PARAMETER GitHubOrg
The name of the GitHub organisation

.PARAMETER RepoSearchString
A search pattern for the repos to query

.EXAMPLE
Set-GitHubSessionInformation -PatToken <not-a-real-pat-token>
Get-GitHubOrgTeamsAndPermissions -GitHubOrg MyGitHubOrg -RepoSearchString MyRepo
#>
function Get-GitHubOrgTeamsAndPermissions {
    [CmdletBinding()]
    param(
        [string]$GitHubOrg,
        [string]$RepoSearchString
    )

    $Baseurl = "https://api.github.com/graphql"
    $SessionInfo = Get-GitHubSessionInformation

    $HasNextPage = $true
    $PageInfo = ""
    $Repos = @()

    while ($HasNextPage) {
        $TeamsQuery = @"
{
    "query": "query { organization(login: \"$GitHubOrg\") { name teams(first: 100$PageInfo) { totalCount pageInfo { hasNextPage endCursor } nodes { name } } } }"
}
"@
        $Response = Invoke-RestMethod -Method POST -Uri "$($Baseurl)" -Body $TeamsQuery -Headers $SessionInfo.Headers

        $HasNextPage = $Response.data.organization.teams.pageInfo.hasNextPage -eq "True"
        $PageInfo = ", after:\""$($Response.data.organization.teams.pageInfo.endCursor)\"""
        $Teams += $Response.data.organization.teams.nodes.name
    }

    foreach($Team in $Teams) {
        $HasNextPage = $true
        $PageInfo = ""

        $RepoObj = @{
            teamName  = $Team
            teamRepos = @()
        }

        while ($HasNextPage){

            $RepoQuery = @"
{
    "query": "query { organization(login: \"$GitHubOrg\") { team(slug: \"$Team\") { repositories(query: \"$RepoSearchString\", first: 100$PageInfo) { edges { permission node { name } } totalCount pageInfo { endCursor hasNextPage } } name } } }"
}
"@

            $Response = Invoke-RestMethod -Method POST -Uri "$($Baseurl)" -Body $RepoQuery -Headers @{ Authorization = "Bearer $PatToken"; Accept = "application/vnd.github.vixen-preview+json" }

            $HasNextPage = $Response.data.organization.team.repositories.pageInfo.hasNextPage -eq "True"
            $PageInfo = ", after:\""$($Response.data.organization.team.repositories.pageInfo.endCursor)\"""
            $RepoObj.teamRepos += $Response.data.organization.team.repositories.edges
        }

        $Repos += $RepoObj
    }

    $Repos | ForEach-Object {
        return @{
            teamName = $_.teamName
            teamRepos = $_.teamRepos | ForEach-Object {
                if(!([string]::IsNullOrEmpty($_.node.name))){
                    return @{
                        repoPermission = $_.permission
                        repoName       = $_.node.name
                    }
                }
            }
        }
    }

}
