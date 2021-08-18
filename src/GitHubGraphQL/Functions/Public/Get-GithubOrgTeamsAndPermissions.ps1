function Get-GithubOrgTeamsAndPermissions {
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
