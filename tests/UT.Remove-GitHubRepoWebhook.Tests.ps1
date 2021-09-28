Import-Module $PSScriptRoot\..\src\GitHubToolKit.psm1 -Force

Describe "Remove-GitHubRepoWebhook tests" -Tags @("Unit") {

    Context "All mandatory parameters are passed in" {
        Mock Invoke-GitHubRestMethod

        #Skipped tests: uses deprecated method to authenticate with GitHub API that's hardcoded into the script
        It "Should call Invoke-GitHubRestMethod using DELETE on /repos/{Organization}/{Repo Name}/hooks/{Hook id}" -Skip {

        }
    }
}
