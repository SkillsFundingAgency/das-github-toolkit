Import-Module $PSScriptRoot\..\src\GitHubToolKit.psm1 -Force

Describe "Get-GitHubRepoTeamPermission integration tests" -Tags @("Integration") {
    . $PSScriptRoot\IT.Mocks.ps1

    Context "The GitHub API returns a valid response" {
        It "Should return an array of hashtables containing repo teams" {
            Set-GitHubSessionInformation -PatToken $Env:GitHubPatToken
            $Result = Get-GitHubRepoTeamPermission
            $Result.Count | Should -BeGreaterThan 1
            { $Result | Select-Object -ExpandProperty teams | Should -Not -Throw }
        }
    }
}
