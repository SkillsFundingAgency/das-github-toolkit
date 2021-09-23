Import-Module $PSScriptRoot\..\src\GitHubToolKit.psm1 -Force

Describe "Get-GitHubRepoTeamPermission integration tests" -Tags @("Integration") {
    . $PSScriptRoot\IT.Mocks.ps1

    Context "The GitHub API returns a valid response" {
        It "Should return an array of hashtables containing repo teams" {
            Set-GitHubSessionInformation -PatToken $env:GITHUBPATTOKEN
            $Result = Get-GitHubRepoTeamPermission -Verbose #TO DO: remove -Verbose
            $Result.Count | Should -BeGreaterThan 1
            { $Result | Select-Object -ExpandProperty teams | Should -Not -Throw }
        }
    }

    Context "The GitHub API returns a valid response" {
        It "Should return an array of hashtables containing repo teams without any warnings" {
            Mock -CommandName Write-Warning -ModuleName GitHubToolKit
            Mock -CommandName Write-Error -ModuleName GitHubToolKit

            Set-GitHubSessionInformation -PatToken $env:GITHUBPATTOKEN
            $Result = Get-GitHubRepoTeamPermission
            $Result.Count | Should -BeGreaterThan 1
            { $Result | Select-Object -ExpandProperty teams | Should -Not -Throw }
            Assert-MockCalled -CommandName Write-Warning -ModuleName GitHubToolKit -Times 0 -Exactly
            Assert-MockCalled -CommandName Write-Error -ModuleName GitHubToolKit -Times 0 -Exactly
        }
    }
}
