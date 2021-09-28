Import-Module $PSScriptRoot\..\src\GitHubToolKit.psm1 -Force

Describe "Get-GitHubOrgPublicRepos tests" -Tags @("Unit") {
    Mock Invoke-WebRequest

    $Params = @{
        Base64AuthInfo = ""
        OrgName = "FooAgency"
    }

    Context "The GitHub API returns a valid response" {
        #Skipped tests: uses deprecated method to authenticate with GitHub API
        It "Should return an array" -Skip {
        }
    }
}
