function Get-GitHubLicenceInfo {
    [CmdletBinding()]
    param(
        [string]$GitHubOrg,
        [string]$RepoSearchString
    )
    $Baseurl = "https://api.github.com/graphql"
    $SessionInfo = Get-GitHubSessionInformation

    $HasNextPage = $true
    $PageInfo = ""
    $Licences = @()

    while ($HasNextPage) {
        $BranchQuery = @"
{
    "query": "query { organization(login: \"$GitHubOrg\") { repositories(first: 100$PageInfo) { nodes { licenseInfo { name } name isArchived isDisabled } pageInfo { endCursor hasNextPage } } } }"
}
"@

        Write-Verbose "Retrieving page ..."
        $Response = Invoke-RestMethod -Method POST -Uri "$($Baseurl)" -Body $BranchQuery -Headers $SessionInfo.Headers
        $HasNextPage = $Response.data.organization.repositories.pageInfo.hasNextPage -eq "True"
        $PageInfo = ", after:\""$($Response.data.organization.repositories.pageInfo.endCursor)\"""
        $Licences += $Response.data.organization.repositories.nodes
    }

    $Licences | ForEach-Object {
        return @{
            repoName  = $_.name
            repoLicence = $_.licenseInfo.name
        }
    }
}