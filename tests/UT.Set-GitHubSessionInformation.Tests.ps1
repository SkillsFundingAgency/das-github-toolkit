Import-Module $PSScriptRoot\..\src\GitHubToolKit.psm1 -Force

Describe "Set-GitHubSessionInformation tests" -Tags @("Unit") {

    Context "A PAT token is passed to Set-GitHubSessionInformation" {
        It "Should set Accept and Authorization headers in a script variable" {
            InModuleScope GitHubToolKit {
                Set-GitHubSessionInformation -PatToken "not-a-real-pat-token"
                $Script:GithubSessionInformation.Headers["Accept"] | Should -Be "application/vnd.github.v3+json"
                $Script:GithubSessionInformation.Headers["Authorization"] | Should -Be "Bearer not-a-real-pat-token"
            }
        }
    }
}
