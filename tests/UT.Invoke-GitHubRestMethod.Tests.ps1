Import-Module $PSScriptRoot\..\src\GitHubToolKit.psm1 -Force

Describe "Invoke-GitHubRestMethod tests" -Tags @("Unit") {
    Mock Invoke-RestMethod -ModuleName GitHubToolKit -MockWith {
        $Script:ResponseHeaders = @{
            Link = $null
            "X-RateLimit-Resource" = @("core")
            "X-RateLimit-Limit" = @("60")
            "X-RateLimit-Remaining" = @("59")
            "X-RateLimit-Reset" = @("$(Get-Date -Date (Get-Date).AddMinutes(1) -UFormat %s)")
        }
        return @{
            FooKey = "BarValue"
        }
    }
    Mock Start-Sleep -ModuleName GitHubToolKit

    $Params = @{
        Method = "GET"
        URI = "/not-a-real-resource"
    }

    Context "SessionInformation is not set" {
        It "Should throw an error" {
            { Invoke-GitHubRestMethod @Params } | Should -Throw
        }
    }

    Set-GitHubSessionInformation -PatToken "not-a-real-pat-token"

    Context "GitHub API responds with no pagination" {
        It "Should call Invoke-RestMethod once and return a response" {
            $Result = Invoke-GitHubRestMethod @Params
            Assert-MockCalled -CommandName Invoke-RestMethod -ModuleName GitHubToolKit -Times 1 -Exactly
            $Result | Should -BeOfType Hashtable
        }
    }

    Context "GitHub API response includes a pagination link" {
        Mock Invoke-RestMethod -ModuleName GitHubToolKit -ParameterFilter { $Uri -and $Uri -match "q=foobar$"} -MockWith {
            $Script:ResponseHeaders = @{
                Link = @(
                    '<https://api.github.com/search/code?q=foobar&page=2>; rel="next"',
                    '<https://api.github.com/search/code?q=foobar&page=4>; rel="last"'
                )
                "X-RateLimit-Resource" = @("core")
                "X-RateLimit-Limit" = @("60")
                "X-RateLimit-Remaining" = @("59")
                "X-RateLimit-Reset" = @("$(Get-Date -Date (Get-Date).AddMinutes(1) -UFormat %s)")
            }
            return [object[]]@(1, 2, 3)
        }
        Mock Invoke-RestMethod -ModuleName GitHubToolKit -ParameterFilter { $URI -and $URI -match "q=foobar&page=2$"} -MockWith {
            $Script:ResponseHeaders = @{
                Link = @(
                    '<https://api.github.com/search/code?q=foobar&page=3>; rel="next"',
                    '<https://api.github.com/search/code?q=foobar&page=4>; rel="last"'
                )
                "X-RateLimit-Resource" = @("core")
                "X-RateLimit-Limit" = @("60")
                "X-RateLimit-Remaining" = @("59")
                "X-RateLimit-Reset" = @("$(Get-Date -Date (Get-Date).AddMinutes(1) -UFormat %s)")
            }
            return [object[]]@(4, 5, 6)
        }
        Mock Invoke-RestMethod -ModuleName GitHubToolKit -ParameterFilter { $URI -and $URI -match "q=foobar&page=3$"} -MockWith {
            $Script:ResponseHeaders = @{
                Link = @(
                    '<https://api.github.com/search/code?q=foobar&page=4>; rel="next"',
                    '<https://api.github.com/search/code?q=foobar&page=4>; rel="last"'
                )
                "X-RateLimit-Resource" = @("core")
                "X-RateLimit-Limit" = @("60")
                "X-RateLimit-Remaining" = @("59")
                "X-RateLimit-Reset" = @("$(Get-Date -Date (Get-Date).AddMinutes(1) -UFormat %s)")
            }
            return [object[]]@(7, 8, 9)
        }

        Mock Invoke-RestMethod -ModuleName GitHubToolKit -ParameterFilter { $URI -and $URI -match "q=foobar&page=4$"} -MockWith {
            $Script:ResponseHeaders = @{
                Link = @(
                    '<https://api.github.com/search/code?q=foobar&page=4>; rel="next"',
                    '<https://api.github.com/search/code?q=foobar&page=4>; rel="last"'
                )
                "X-RateLimit-Resource" = @("core")
                "X-RateLimit-Limit" = @("60")
                "X-RateLimit-Remaining" = @("59")
                "X-RateLimit-Reset" = @("$(Get-Date -Date (Get-Date).AddMinutes(1) -UFormat %s)")
            }
            return [object[]]@(10, 11, 12)
        }

        $Params["URI"] = "/search/code?q=foobar"
        
        It "Should call Invoke-RestMethod once per page and return an array combining all the items from each response" {
            $Result = Invoke-GitHubRestMethod @Params
            Assert-MockCalled -CommandName Invoke-RestMethod -ModuleName GitHubToolKit -Times 4 -Exactly
            $Result.Count | Should -Be 12
        }
    }

    Context "GitHub API responds with a remaining rate limit header less than 25% of the the limit" {
        Mock Invoke-RestMethod -ModuleName GitHubToolKit -MockWith {
            $Script:ResponseHeaders = @{
                Link = $null
                "X-RateLimit-Resource" = @("core")
                "X-RateLimit-Limit" = @("60")
                "X-RateLimit-Remaining" = @("14")
                "X-RateLimit-Reset" = @("$(Get-Date -Date (Get-Date).AddMinutes(1) -UFormat %s)")
            }
            return @{
                FooKey = "BarValue"
            }
        }
        
        It "Should call Start-Sleep until the reset period has passed" {
            $Result = Invoke-GitHubRestMethod @Params
            Assert-MockCalled -CommandName Invoke-RestMethod -ModuleName GitHubToolKit -Times 1 -Exactly
            Assert-MockCalled -CommandName Start-Sleep -ModuleName GitHubToolKit -Times 1 -Exactly -ParameterFilter { $Seconds -gt 50 }
            $Result | Should -BeOfType Hashtable  
        }
    }
}
