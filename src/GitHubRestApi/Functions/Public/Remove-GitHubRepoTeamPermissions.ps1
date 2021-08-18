<#

.SYNOPSIS
Removes team permissions on github repos.

.DESCRIPTION
Removes team permissions on github repos using the github rest API.

.PARAMETER PatToken
The Github PAT token. The user requires admin rights on the targeted repo.

.PARAMETER GitHubOrg
The Org the repo belongs to. I.E SkillsFundingAgency

.PARAMETER TeamSlug
Github generates a teamslug for each team. Das-Platform-Engineering would be das-platform-engineering. Any spaces in the name get convereted to -.
The teamslug can be double checked by using the github api GET /orgs/{org}/teams to list teams

.PARAMETER Repo
Name of the repo to target

.PARAMETER DryRun
Writes an output of the changes that would be made with no actual execution. No api calls are performed in this process.

.EXAMPLE
Remove-GitHubRepoTeamPermissions -PatToken $PatToken -GitHubOrg "SkillsFundingAgency" -TeamSlug "das-platform-engineering" -Repo das-tools-service -DryRun $false

.NOTES
The documentation for the github endpoint used by this function can be found here:
https://docs.github.com/en/free-pro-team@latest/rest/reference/teams#remove-a-project-from-a-team

#>
function Remove-GithubRepoTeamPermissions {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [String]$PatToken,
        [Parameter(Mandatory = $true)]
        [String]$GitHubOrg,
        [Parameter(Mandatory = $true)]
        [String]$TeamSlug,
        [Parameter(Mandatory = $true)]
        [String]$Repo,
        [Parameter(Mandatory = $false)]
        [bool]$DryRun = $true
    )
    $BaseUrl = "https://api.github.com"

    $RequestUrl = "$BaseUrl/orgs/$GitHubOrg/teams/$TeamSlug/repos/$GitHubOrg/$Repo"

    $Headers = @{
        'Content-Type' = 'application/json'
        Authorization  = "Bearer $PatToken"
    }

    if($DryRun){
        Write-Warning "DryRun: Would be running DELETE $RequestUrl"
    } else {
        Write-Host "Removing Team $TeamSlug from $Repo"
        $Response = Invoke-RestMethod -Method DELETE -Uri "$RequestUrl" -Headers $Headers
    }

    return $Response
}
