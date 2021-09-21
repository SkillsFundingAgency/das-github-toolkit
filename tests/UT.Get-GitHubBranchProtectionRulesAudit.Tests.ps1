Import-Module $PSScriptRoot\..\src\GitHubToolKit.psm1 -Force

Describe "Get-GitHubBranchProtectionRulesAudit tests" -Tags @("Unit") {
    Mock Get-GithubRepoBranchProtectionRules -ModuleName GitHubToolKit -MockWith {
        return @(
            @{
                repoName = "foo-bar-repo"
                repoBranchProtectionRules = @{
                    branchName = "master"
                    requiresStrictStatusChecks = $true
                    requiresStatusChecks = $true
                    requiresApprovingReviews = $true
                    requiredApprovingReviewCount = 1
                }
            },
            @{
                repoName = "foo-foo-repo"
                repoBranchProtectionRules = @(
                    @{
                    branchName = "master"
                    requiresStrictStatusChecks = $true
                    requiresStatusChecks = $true
                    requiresApprovingReviews = $true
                    requiredApprovingReviewCount = 1
                    },
                    @{
                        branchName = "dev"
                        requiresStrictStatusChecks = $false
                        requiresStatusChecks = $true
                        requiresApprovingReviews = $true
                        requiredApprovingReviewCount = 1
                    }
                )
            }
        )
    }

    $PathToConfigFile = "$PSScriptRoot\test-config.json"
    $Config = Get-Content -Path $PathToConfigFile -Raw | ConvertFrom-Json

    BeforeEach {
        $Params = @{
            AuditResults = @(
                @{
                    RepositoryName = "foo-bar-repo"
                    IsArchived = $false
                    IsPrivateRepository = $true
                },
                @{
                    RepositoryName = "foo-foo-repo"
                    IsArchived = $false
                    IsPrivateRepository = $true
                },
                @{
                    RepositoryName = "bar-foo-repo"
                    IsArchived = $true
                    IsPrivateRepository = $false
                }
            )
            Config = $Config
        }
    }

    Context "An array of GitHubRepoAudit objects is passed in and the GitHub API returns valid responses to all API calls" {
        It "Returns an array of GitHubRepoAudit objects with the BranchProtection property populated" {
            InModuleScope GitHubToolKit {
                $Result = Get-GitHubBranchProtectionRulesAudit @Params
                $Result.Count | Should -Be 2
                $Result[0].GetType().Name | Should -Be "GitHubRepoAudit"
                { $Result | Select-Object -ExpandProperty BranchProtection -ErrorAction Stop } | Should -Not -Throw
            }
        }
    }
}

