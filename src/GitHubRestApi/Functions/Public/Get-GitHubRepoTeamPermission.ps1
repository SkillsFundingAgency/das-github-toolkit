<#
.SYNOPSIS
Gets a list of teams associated with each repo in a specified GitHub organisation

.DESCRIPTION
Gets a list of teams associated with each repo in a specified GitHub organisation

.PARAMETER GitHubOrg
(optional) The GitHub organsation to get repos from

.EXAMPLE
Set-GitHubSessionInformation -PatToken <not-a-real-pat-token>
Get-GitHubRepoTeamPermission
#>
function Get-GitHubRepoTeamPermission {
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
