﻿Import-Module $PSScriptRoot\..\src\GitHubToolKit.psm1 -Force

Describe "Search-DotNetFrameworks tests" -Tags @("Unit") {

    Mock Get-GitHubRepos -ModuleName GitHubToolKit -MockWith {
        return @(
            @{
                name = "foo-bar-repo"
                isArchived = $false
                isPrivate = $true
            },
            @{
                name = "foo-foo-repo"
                isArchived = $false
                isPrivate = $true
            }
        )
    }

    Mock Invoke-GitHubRestMethod -ModuleName GitHubToolKit -ParameterFilter { $Uri -match "\/search\/code\?q=org%3A.*" } -MockWith {
        return @(
            @{
                total_count = 1
                items = @(
                    @{
                        name = "FooApp.csproj"
                        path = "src/App/FooApp.csproj"
                        repository = @{
                            name = "foo-bar-repo"
                        }
                    }
                )
            },
            @{
                total_count = 1
                items = @(
                    @{
                        name = "FooApi.csproj"
                        path = "src/Api/FooApi.csproj"
                        repository = @{
                            name = "foo-bar-repo"
                        }
                    }
                )
            }
        )
    }

    $Params = @{
        RepositoryPrefix = "foo-"
    }

    Mock Invoke-GitHubRestMethod -ModuleName GitHubToolKit -ParameterFilter { $Uri -match "\/repos.*" } -MockWith {
        return '<?xml version="1.0" encoding="utf-8"?><TargetFrameworkVersion>v4.5.1</TargetFrameworkVersion>'
    }
    
    Context "The GitHub API returns a valid response" {
        It "Should return an array of GitHubDotNetFrameworkSearch objects" {
            $Result = Search-DotNetFrameworks @Params
            $Result.Count | Should -Be 4
            $Result[0] | Should -BeOfType GitHubDotNetFrameworkSearch
        }
    }
}
