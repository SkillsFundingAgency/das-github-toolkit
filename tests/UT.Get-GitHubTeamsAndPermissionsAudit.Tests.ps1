Import-Module $PSScriptRoot\..\src\GitHubToolKit.psm1 -Force

Describe "Get-GitHubTeamsAndPermissionsAudit tests" -Tags @("Unit") {
    Mock Get-GitHubRepoTeamPermission -ModuleName GitHubToolKit -MockWith {
        return @(
            @{
                repository = @{
                    name = "foo-bar-repo"
                }
                teams = @(
                    @{
                        name = "Team Foo"
                        permission = "push"
                    },
                    @{
                        name = "Team Bar"
                        permission = "admin"
                    }
                )
            },
            @{
                repository = @{
                    name = "foo-foo-repo"
                }
                teams = @(
                    @{
                        name = "Team Foo"
                        permission = "push"
                    },
                    @{
                        name = "Team Bar"
                        permission = "admin"
                    }
                )
            },
            @{
                repository = @{
                    name = "bar-foo-repo"
                }
                teams = @(
                    @{
                        name = "Team Bar"
                        permission = "admin"
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
        It "Returns an array of GitHubRepoAudit objects with the AccessControlList property populated" {
            InModuleScope GitHubToolKit {
                $Result = Get-GitHubTeamsAndPermissionsAudit @Params
                $Result.Count | Should -Be 3
                $Result[0].GetType().Name | Should -Be "GitHubRepoAudit"
                { $Result | Select-Object -ExpandProperty AccessControlList -ErrorAction Stop } | Should -Not -Throw
            }
        }
    }
}
