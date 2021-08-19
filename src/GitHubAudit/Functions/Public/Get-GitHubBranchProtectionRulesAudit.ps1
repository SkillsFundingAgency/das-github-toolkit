<#
.SYNOPSIS
Appends Branch Protection rules to the results of a GitHubAudit produced by Get-GitHubAudit

.DESCRIPTION
Appends Branch Protection rules to the results of a GitHubAudit produced by Get-GitHubAudit

.PARAMETER AuditResults
An array of GitHubRepoAudit objects

.PARAMETER Config
A GitHubAudit config file converted from json

.EXAMPLE
$Config = Get-Content -Path $PathToConfigFile -Raw | ConvertFrom-Json
$Audit = @()
$Audit += New-Object -TypeName GitHubRepoAudit
$Audit = Get-GitHubBranchProtectionRulesAudit -AuditResults $Audit -Config $Config
#>
function Get-GitHubBranchProtectionRulesAudit {
    [CmdletBinding()]
    param(
        [GitHubRepoAudit[]]$AuditResults,
        [object]$Config
    )

    $BranchProtectedRepos = Get-GithubRepoBranchProtectionRules -GithubOrg $Config.managedRepos.organisation

    $PropertiesToCompare = (New-Object -TypeName GitHubRepoBranchProtection | Get-Member -MemberType Property).Name
    # Remove BranchName property.  In order to handle alternative names for the default branch (eg master, main) the NormalisedBranchName is used for comparison
    $PropertiesToCompare = $PropertiesToCompare | Where-Object { $_ -ne "BranchName" }

    foreach ($BranchProtectedRepo in $BranchProtectedRepos) {
        $BranchProtectionRules = @()
        foreach ($BranchProtectionOutput in $BranchProtectedRepo.repoBranchProtectionRules) {
            $BranchProtectionRule = New-Object -TypeName GitHubRepoBranchProtection -Property @{
                BranchName = $BranchProtectionOutput.branchName
                NormalisedBranchName = $BranchProtectionOutput.branchName -in $Config.managedRepos.defaultBranchAlternativeNames ? "master" : $BranchProtectionOutput.branchName
                StrictStatusChecks = $BranchProtectionOutput.requiresStrictStatusChecks
                StatusChecks = $BranchProtectionOutput.requiresStatusChecks
                ApprovingReviews = $BranchProtectionOutput.requiresApprovingReviews
                RequiredApprovingReviewCount = $BranchProtectionOutput.requiredApprovingReviewCount
            }
            $BranchProtectionRules += $BranchProtectionRule
        }

        $ExpectedBranchProtectionRules = @()
        foreach ($ExpectedBranchProtectionRule in $Config.expectedBranchProtection) {
            $ExpectedBranchProtectionRules += [GitHubRepoBranchProtection]$ExpectedBranchProtectionRule
        }

        $CorrectConfiguration = $false
        $Comparison = Compare-Object -ReferenceObject $ExpectedBranchProtectionRules -DifferenceObject $BranchProtectionRules -Property $PropertiesToCompare
        if ($null -eq $Comparison) {
            $CorrectConfiguration = $true
        }
        ##TO DO: consider whether this is the correct logic.  it 'should' only return true if the repo has at least the same branch protections rules as expected config
        elseif (($Comparison | Where-Object { $_.SideIndicator -eq "==" }).Count -eq $ExpectedBranchProtectionRules.Count) {
            $CorrectConfiguration = $true
        }

        $BranchProtectionAudit = New-Object -TypeName GitHubAuditResult -Property @{
            ExpectedValue = $ExpectedBranchProtectionRules
            ActualValue = $BranchProtectionRules
            CorrectConfiguration = $CorrectConfiguration
        }

        Remove-Variable -Name ExistingAuditResult -ErrorAction SilentlyContinue
        $ExistingAuditResult = $AuditResults | Where-Object { $_.RepositoryName -eq $BranchProtectedRepo.repoName }
        if ($ExistingAuditResult) {
            $ExistingAuditResult.BranchProtection += $BranchProtectionAudit
        }
        else {
            $AuditResult = New-Object -TypeName GitHubRepoAudit -Property @{ RepositoryName = $BranchProtectedRepo.repoName; BranchProtection = $BranchProtectionAudit }
            $AuditResults += $AuditResult
        }

    }

    $AuditResults
}
