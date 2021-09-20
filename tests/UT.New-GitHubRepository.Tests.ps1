Import-Module $PSScriptRoot\..\src\GitHubToolKit.psm1 -Force

Describe "New-GitHubRepository tests" -Tags @("Unit") {

    Context "All mandatory parameters are passed in" {
        
        #Skipped tests: uses deprecated method to authenticate with GitHub API that's hardcoded into the script
        It "Should call Invoke-RestMethod using POST on /user/repos" -Skip {

        }
    }
}
