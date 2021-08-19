<#
.SYNOPSIS
Appends repo Licence to the results of a GitHubAudit produced by Get-GitHubAudit

.DESCRIPTION
Appends repo Licence to the results of a GitHubAudit produced by Get-GitHubAudit

.PARAMETER AuditResults
An array of GitHubRepoAudit objects

.PARAMETER Config
A GitHubAudit config file converted from json

.EXAMPLE
$Config = Get-Content -Path $PathToConfigFile -Raw | ConvertFrom-Json
$Audit = @()
$Audit += New-Object -TypeName GitHubRepoAudit
$Audit = Get-GitHubLicencesAudit -AuditResults $Audit -Config $Config
#>
function Get-GitHubLicencesAudit {
    [CmdletBinding()]
    param(
        [GitHubRepoAudit[]]$AuditResults,
        [object]$Config
    )

    $Licences = Get-GitHubLicenceInfo -GithubOrg $Config.managedRepos.organisation -RepoSearchString $Config.managedRepos.pattern

    Write-Verbose "Retrieved $($Licences.Count) licences."
    foreach ($Licence in $Licences) {
        Remove-Variable -Name ExistingAuditResult -ErrorAction SilentlyContinue
        $ExistingAuditResult = $AuditResults | Where-Object { $_.RepositoryName -eq $Licence.repoName }
        $LicenceAudit = New-Object -TypeName GitHubAuditResult -Property @{
            ExpectedValue = $Config.expectedLicence
            ActualValue = $Licence.repoLicence
            CorrectConfiguration = $Config.expectedLicence -eq $Licence.repoLicence
        }
        if ($ExistingAuditResult) {
            $ExistingAuditResult.Licence = $LicenceAudit
        }
        else {
            $AuditResult = New-Object -TypeName GitHubRepoAudit -Property @{ RepositoryName = $Licence.repoName; Licence = $LicenceAudit }
            $AuditResults += $AuditResult
        }
    }

    $AuditResults
}
