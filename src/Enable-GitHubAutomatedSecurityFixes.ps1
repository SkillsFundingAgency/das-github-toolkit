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
