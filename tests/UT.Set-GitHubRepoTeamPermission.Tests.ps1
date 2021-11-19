Import-Module $PSScriptRoot\..\src\GitHubToolKit.psm1 -Force

Describe "Set-GitHubRepoTeamPermission tests" -Tags @("Unit") {
    Mock Invoke-RestMethod -ModuleName GitHubToolKit

    BeforeEach {
        $Params = @{
            PatToken = "not-a-real-pat-token"
            GitHubOrg = "FooBarAgency"
            TeamSlug = "foo-contributor"
            Permission = "pull"
            Repo = "foo-bar-repo"
        }
    }

    Context "All mandatory parameters are passed in with DryRun set to false" {
        It "Should call Invoke-RestMethod" {
            $Params["DryRun"] = $false
            $Result = Set-GitHubRepoTeamPermission @Params
            Assert-MockCalled -CommandName Invoke-RestMethod -ModuleName GitHubToolKit -Times 1 -Exactly
        }
    }

    Context "All mandatory parameters are passed" {
        It "Should not call Invoke-RestMethod" {
            $Result = Set-GitHubRepoTeamPermission @Params
            Assert-MockCalled -CommandName Invoke-RestMethod -ModuleName GitHubToolKit -Times 0 -Exactly
        }
    }
}
