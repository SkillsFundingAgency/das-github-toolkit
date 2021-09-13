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

    $Params = @{
        Method = "GET"
        URI = "/not-a-real-resource"
    }

    Set-GitHubSessionInformation -PatToken "not-a-real-pat-token"

    Context "GitHub API responds with no pagination" {
        It "Should call Invoke-RestMethod once and return a response" {
            $Result = Invoke-GitHubRestMethod @Params
            Assert-MockCalled -CommandName Invoke-RestMethod -ModuleName GitHubToolKit -Times 1
            $Result | Should -BeOfType Hashtable
        }
    }

    ##TO DO: test rate limit
    ##TO DO: test pagination
    ##TO DO: test SessionInfo not set
}
