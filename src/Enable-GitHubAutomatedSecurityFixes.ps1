<#
.SYNOPSIS
Enables Dependabot security updates for all repos in a GitHub organisation with names matching a supplied pattern

.DESCRIPTION
Enables Dependabot security updates for all repos in a GitHub organisation with names matching a supplied pattern
https://docs.github.com/en/code-security/supply-chain-security/managing-vulnerabilities-in-your-projects-dependencies/configuring-dependabot-security-updates

.PARAMETER GithubUsername
GitHub username - possibly deprecated authentication method

.PARAMETER GithubPATToken
GitHub PAT token - possibly deprecated authentication method

.PARAMETER OrgName
The GitHub organisation to apply the changes to 

.PARAMETER RepoSearchString
A prefix to match the repo names against

.EXAMPLE
.\Enable-GitHubAutomatedSecurityFixes.ps1 -GithubUsername MyUserName -GithubPATToken abcd1234 -OrgName MyGitHubOrg -RepoSearchString "abc-"
#>
param(
    [string]$GithubUsername,
    [string]$GithubPATToken,
    [string]$OrgName,
    [string]$RepoSearchString
)

$Base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $GithubUsername, $GithubPATToken)))
$Repos = . "$PSScriptRoot/Get-GithubOrgPublicRepos.ps1" -GithubUsername $GithubUsername -Base64AuthInfo $Base64AuthInfo

$SetRepos = $Repos | Where-Object { $_.name -like "$RepoSearchString*" -and !$_.archived }

foreach ($Repo in $SetRepos) {
    $Route = "/repos/$OrgName/$($Repo.name)/automated-security-fixes"
    $Response = Invoke-WebRequest -Uri "$BaseUrl$Route" -Headers @{ Accept = "application/vnd.github.london-preview+json"; Authorization = "Basic $Base64AuthInfo" } -Method Put
}
