Import-Module $PSScriptRoot\..\src\GitHubToolKit.psm1 -Force

Describe "Get-GitHubRepoBranchProtectionRule tests" -Tags @("Unit") {

    Context "The GitHub API returns a valid, single page response" {
        Mock Invoke-RestMethod -ModuleName GitHubToolKit -MockWith {
            $BranchNameNodes = @(
                New-Object -TypeName PSCustomObject -Property @{ name = "master" }
            )
            $MatchingRefs = New-Object -TypeName PSCustomObject -Property @{ nodes = $BranchNameNodes }
            $RuleNodes = @(
                New-Object -TypeName PSCustomObject -Property @{ matchingRefs = $MatchingRefs; requiresStrictStatusChecks = $true; requiresStatusChecks = $true; requiresApprovingReviews = $true; requiredApprovingReviewCount = 2 }
            )
            $BranchProtectionRules = New-Object -TypeName PSCustomObject -Property @{ nodes = $RuleNodes }

            $RepoNodes = @(
                New-Object -TypeName PSCustomObject -Property @{ name = "foo-bar-repo"; branchProtectionRules = $BranchProtectionRules }
                New-Object -TypeName PSCustomObject -Property @{ name = "foo-foo-repo"; branchProtectionRules = $BranchProtectionRules }
            )

            $PageInfo = New-Object -TypeName PSCustomObject -Property @{ endCursor = "nOTarEALcURSOR=="; hasNextPage = "False" }
            $Repositories = New-Object -TypeName PSCustomObject -Property @{ nodes = $RepoNodes; pageInfo = $PageInfo }
            $Organization = New-Object -TypeName PSCustomObject -Property @{ repositories = $Repositories }
            $Data = New-Object -TypeName PSCustomObject -Property @{ organization = $Organization }
            $ReturnObject = New-Object -TypeName PSCustomObject -Property @{ data = $Data }
            return $ReturnObject
        }

        It "Should call Invoke-RestMethod once and return an array of teams with each team item having another array of branch protection rules" {
            Set-GitHubSessionInformation -PatToken "not-a-real-pat-token"
            $Result = Get-GitHubRepoBranchProtectionRule -GitHubOrg SkillsFundingAgency
            $Result.Count | Should -Be 2
            { $Result | Select-Object -ExpandProperty repoBranchProtectionRules } | Should -Not -Throw
            Assert-MockCalled -CommandName Invoke-RestMethod -ModuleName GitHubToolKit -Times 1 -Exactly
        }
    }
}
