Import-Module $PSScriptRoot\..\src\GitHubToolKit.psm1 -Force

Describe "Get-GitHubRepoPullRequest tests" -Tags @("Unit") {

    Context "The GitHub API returns a valid response" {
        #Skipped tests: No value in test for simple function
        It "Should output the results" -Skip {
        }
    }
}
