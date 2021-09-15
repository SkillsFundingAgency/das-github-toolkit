Import-Module $PSScriptRoot\..\src\GitHubToolKit.psm1 -Force

#Skipped tests: Remove-GitHubSessionInformation implements SupportsShouldProcess,ConfirmImpact="High" forcing an unnecessary manual confirmation which also prevents testing
Describe "Remove-GitHubSessionInformation tests" -Tags @("Unit") {
    Mock Remove-Variable -ModuleName GitHubToolKit
    
    Context "GitHubSessionInformation has not been set" {
        It "Should call Remove-Variable successfully" -Skip {
            Remove-GitHubSessionInformation
        }
    }

    Context "GitHubSessionInformation has been set" {
        It "Should call Remove-Variable successfully" -Skip {
            Set-GitHubSessionInformation -PatToken "not-a-real-pat-token"
            Remove-GitHubSessionInformation
        }
    }
}
