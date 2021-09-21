Import-Module $PSScriptRoot\..\src\GitHubToolKit.psm1 -Force

Describe "Enable-GitHubAutomatedSecurityFixes tests" -Tags @("Unit") {
    #Mock Get-GithubOrgPublicRepos
    Mock Invoke-WebRequest

    Context "All parameters are passed in" {
        #Skipped tests: calls Get-GithubOrgPublicRepos.ps1 as a script rather than a function so it can't be mocked
        It "Should call Invoke-WebRequest once for each repo" -Skip {

        }
    }
}
