Import-Module $PSScriptRoot\..\src\GitHubToolKit.psm1 -Force

Describe "Get-GitHubRepoTeamPermission tests" -Tags @("Unit") {

    Context "The GitHub API returns a valid response" {
        Mock Invoke-GitHubRestMethod -ModuleName GitHubToolKit -ParameterFilter { $Uri -match "\/orgs\/.*\/repos" } -MockWith {
            @(
                @{
                    id = 12345678
                    name = "foo-bar-repo"
                },
                @{
                    id = 87654321
                    name = "foo-foo-repo"
                }
            )
        }

        Mock Invoke-GitHubRestMethod -ModuleName GitHubToolKit -ParameterFilter { $Uri -match "\/repos\/.*\/.*\/teams" } -MockWith {
            @(
                @{
                    id = 12345678
                    name = "foo-contributor"
                },
                @{
                    id = 87654321
                    name = "foo-admin"
                }
            )
        }

        It "Should return an array of hashtables containing repo teams" {
            Set-GitHubSessionInformation -PatToken "not-a-real-pat-token"
            $Result = Get-GitHubRepoTeamPermission
            $Result.Count | Should -Be 2
            { $Result | Select-Object -ExpandProperty teams | Should -Not -Throw }
        }
    }
}
