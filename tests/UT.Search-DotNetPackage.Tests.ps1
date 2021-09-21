Import-Module $PSScriptRoot\..\src\GitHubToolKit.psm1 -Force

Describe "Search-DotNetPackages tests" -Tags @("Unit") {
    Mock Invoke-GitHubRestMethod -ModuleName GitHubToolKit -ParameterFilter { $Uri -match "\/search\/code\?q=org%3A.*" } -MockWith {
        return @{
            total_count = 2
            items = @(
                @{
                    name = "FooApp.csproj"
                    path = "src/App/FooApp.csproj"
                    repository = @{
                        name = "foo-bar-repo"
                    }
                },
                @{
                    name = "FooApi.csproj"
                    path = "src/Api/FooApi.csproj"
                    repository = @{
                        name = "foo-bar-repo"
                    }
                }
            )
        }
    }

    Mock Invoke-GitHubRestMethod -ModuleName GitHubToolKit -ParameterFilter { $Uri -match "\/repos.*" } -MockWith {
        return '<PackageReference Include="FooPackage" Version="1.1.1" />'
    }

    $Params = @{
        PackageName = "FooPackage"
    }

    Context "The GitHub API returns a valid response" {
        It "Should return an array of GitHubPackageSearch" {
            $Result = Search-DotNetPackage @Params
            $Result.Count | Should -Be 2
            $Result[0].GetType().Name | Should -Be "GitHubPackageSearch"
        }
    }
}
