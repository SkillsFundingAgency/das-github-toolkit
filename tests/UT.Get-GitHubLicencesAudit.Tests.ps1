Import-Module $PSScriptRoot\..\src\GitHubToolKit.psm1 -Force

Describe "Get-GitHubLicencesAudit tests" -Tags @("Unit") {
    Mock Get-GitHubLicenceInfo -ModuleName GitHubToolKit -MockWith {
        return @(
            @{
                repoName = "foo-bar-repo"
                repoLicence = "Foo Licence"
            },
            @{
                repoName = "foo-foo-repo"
                repoLicence = "Foo Licence"
            },
            @{
                repoName = "bar-foo-repo"
                repoLicence = "Bar Licence"
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
        It "Returns an array of GitHubRepoAudit objects with the Licence property populated" {
            InModuleScope GitHubToolKit {
                $Result = Get-GitHubLicencesAudit @Params
                $Result.Count | Should -Be 3
                $Result[0].GetType().Name | Should -Be "GitHubRepoAudit"
                { $Result | Select-Object -ExpandProperty Licence -ErrorAction Stop } | Should -Not -Throw
            }
        }
    }
}
