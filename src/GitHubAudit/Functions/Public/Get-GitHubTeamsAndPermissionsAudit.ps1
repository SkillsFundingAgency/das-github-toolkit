<#
.SYNOPSIS
Appends Teams and Permissions to the results of a GitHubAudit produced by Get-GitHubAudit

.DESCRIPTION
Appends Teams and Permissions to the results of a GitHubAudit produced by Get-GitHubAudit

.PARAMETER AuditResults
An array of GitHubRepoAudit objects

.PARAMETER Config
A GitHubAudit config file converted from json

.EXAMPLE
$Config = Get-Content -Path $PathToConfigFile -Raw | ConvertFrom-Json    
$Audit = @()
$Audit += New-Object -TypeName GitHubRepoAudit
$Audit = Get-GitHubTeamsAndPermissionsAudit -AuditResults $Audit -Config $Config
#>
function Get-GitHubTeamsAndPermissionsAudit {
    [CmdletBinding()]
    param(
        [GitHubRepoAudit[]]$AuditResults,
        [object]$Config
    )

    $Repos = Get-GithubRepoTeamPermissions

    $PropertiesToCompare = (New-Object -TypeName GitHubRepoAccessControlItem | Get-Member -MemberType Property).Name

    foreach ($Repo in $Repos) {
        $ActualAcl = @()
        foreach ($Team in $Repo.teams) {
            $TeamPermission = New-Object -TypeName GitHubRepoAccessControlItem -Property @{
                TeamName = $Team.name
                Permission = $Team.Permission
            }
            $ActualAcl += $TeamPermission
        }

        $ExpectedAcl = @()
        foreach ($ExpectedAcRule in $Config.expectedTeams) {
            $ExpectedAcl += [GitHubRepoAccessControlItem]$ExpectedAcRule
        }

        $CorrectConfiguration = $false
        $Comparison = Compare-Object -ReferenceObject $ExpectedAcl -DifferenceObject $ActualAcl -Property $PropertiesToCompare
        if ($null -eq $Comparison) {
            $CorrectConfiguration = $true
        }
        ##TO DO: consider whether this is the correct logic.  it 'should' only return true if the repo has at least the same branch protections rules as expected config
        elseif (($Comparison | Where-Object { $_.SideIndicator -eq "==" }).Count -eq $ExpectedAcl.Count) {
            $CorrectConfiguration = $true
        }

        $AclAudit = New-Object -TypeName GitHubAuditResult -Property @{
            ExpectedValue = $ExpectedAcl
            ActualValue = $ActualAcl
            CorrectConfiguration = $CorrectConfiguration
        }

        Remove-Variable -Name ExistingAuditResult -ErrorAction SilentlyContinue
        $ExistingAuditResult = $AuditResults | Where-Object { $_.RepositoryName -eq $Repo.repository.name }
        if ($ExistingAuditResult) {
            $ExistingAuditResult.AccessControlList = $AclAudit
        }
        else {
            $AuditResult = New-Object -TypeName GitHubRepoAudit -Property @{ RepositoryName = $Repo.repository.name; AccessControlList = $AclAudit }
            $AuditResults += $AuditResult
        }
    }

    $AuditResults
}
