Import-Module $PSScriptRoot\..\src\GitHubToolKit.psm1 -Force

Describe "Get-GitHubEnvironment tests" -Tags @("Unit") {

    Context "The GitHub API returns a valid, single page response" {
        Mock Invoke-GitHubRestMethod -ModuleName GitHubToolKit -ParameterFilter { $Uri -match "\/repos\/.*\/environments" } -MockWith {
            @{
                total_count = 2
                environments =             @(
                    @{
                        id = 12345678
                        name = "foo-bar-environment"
                    },
                    @{
                        id = 87654321
                        name = "foo-foo-environment"
                    }
                )
            }
        }

        $Params = @{
            GitHubOrg = "FooAgency"
            GitHubRepo = "foo-bar-repo"
        }

        It "Should return an array of hashtables containing environments" {
            Set-GitHubSessionInformation -PatToken "not-a-real-pat-token"
            $Result = Get-GitHubEnvironment @Params
            $Result.Count | Should -Be 2
            $Result[0].name | Should -Be "foo-bar-environment"
        }
    }
}
