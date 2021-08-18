function Get-GithubRepoTeamPermissions {
    [CmdletBinding()]
    param(
        [string]$GitHubOrg = "SkillsFundingAgency"
    )

    $Repos = Invoke-GitHubRestMethod -Method GET -URI "/orgs/$GitHubOrg/repos"
    $RepoTeams = @()
    
    foreach ($Repo in $Repos) {
        $Teams = Invoke-GitHubRestMethod -Method GET -URI "/repos/$GitHubOrg/$($Repo.name)/teams"
        $RepoTeams += @{
            repository = $Repo
            teams = $Teams
        }
    }

    $RepoTeams
}