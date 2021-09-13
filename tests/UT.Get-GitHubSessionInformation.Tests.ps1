Import-Module $PSScriptRoot\..\src\GitHubToolKit.psm1 -Force

Describe "Get-GitHubSessionInformation tests" -Tags @("Unit") {
    Mock Write-Output -ModuleName GitHubToolKit

    Context "No session information has been set" {
        It "Should not call Write-Output" {
                $null = Get-GitHubSessionInformation
                Assert-MockCalled -CommandName Write-Output -ModuleName GitHubToolKit -Times 0
        }
    }

    Context "Session information has been set" {
        It "Should call Write-Output once" {
                Set-GitHubSessionInformation -PatToken "not-a-real-pat-token"
                $null = Get-GitHubSessionInformation
                Assert-MockCalled -CommandName Write-Output -ModuleName GitHubToolKit -Times 1
        }
    }
}
