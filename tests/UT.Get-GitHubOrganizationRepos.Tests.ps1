Import-Module $PSScriptRoot\..\src\GitHubToolKit.psm1 -Force

Describe "Get-GitHubOrganizationRepos tests" -Tags @("Unit") {

    Context "The GitHub API returns a valid response" {
        Mock Invoke-GitHubRestMethod
        Mock Export-Csv
        
        #Skipped tests: uses deprecated method to authenticate with GitHub API that's hardcoded into the script
        It "Should output the results to a file" -Skip {
        }
    }
}
