Import-Module $PSScriptRoot\..\src\GitHubToolKit.psm1 -Force

Describe "Update-AzurePipelineDependencies tests" -Tags @("Unit") {
    Mock Get-GitHubRepo -ModuleName GitHubToolKit -MockWith {
        @(
            @{
                name             = "foo-bar-repo"
                isArchived       = $false
                isPrivate        = $false
                defaultBranchRef = @{
                    name = "main"
                }
            }
        )
    }

    Mock Get-GitHubRepoFileContent -ModuleName GitHubToolKit -MockWith {
        @{
            Sha     = "not-a-real-sha"
            Content =
            @'
resources:
  repositories:
  - repository: self
  - repository: das-platform-building-blocks
    type: github
    name: FooOrg/FooRepository
    ref: refs/tags/0.4.34
    endpoint: FooServiceConnection
  - repository: das-platform-automation
    type: github
    name: FooOrg/BarRepository
    ref: refs/tags/4.5.14
    endpoint: FooServiceConnection
'@
        }
    }

    Mock Get-GitHubRepoRelease -ModuleName GitHubToolKit -MockWith {
        @(
            @{
                tag_name = "10.0.0"
            }
            @{
                tag_name = "9.2.0"
            }
        )
    }

    Mock Get-GithubRepoBranchRef -ModuleName GitHubToolKit -MockWith {
        @{
            object = @{
                sha = "not-a-real-sha"
            }
        }
    }

    Mock New-GitHubRepoBranch -ModuleName GitHubToolKit -MockWith {
    }

    Mock Set-GitHubRepoFileContent -ModuleName GitHubToolKit -MockWith {
    }

    Context "All parameters are passed in" {
        It "Should call the relevant GitHubToolKit functions once" {
            Set-GitHubSessionInformation -PatToken "not-a-real-pat-token"
            Update-AzurePipelineDependencies -GitHubOrganisation FooOrganisation -RepositoryPrefix foo-
            Assert-MockCalled -CommandName Get-GitHubRepo -ModuleName GitHubToolKit -Times 1 -Exactly
            Assert-MockCalled -CommandName Get-GitHubRepoFileContent -ModuleName GitHubToolKit -Times 2 -Exactly
            Assert-MockCalled -CommandName Get-GitHubRepoRelease -ModuleName GitHubToolKit -Times 2 -Exactly
            Assert-MockCalled -CommandName Get-GithubRepoBranchRef -ModuleName GitHubToolKit -Times 1 -Exactly
            Assert-MockCalled -CommandName New-GitHubRepoBranch -ModuleName GitHubToolKit -Times 1 -Exactly
            Assert-MockCalled -CommandName Set-GitHubRepoFileContent -ModuleName GitHubToolKit -Times 1 -Exactly
        }
    }
}
