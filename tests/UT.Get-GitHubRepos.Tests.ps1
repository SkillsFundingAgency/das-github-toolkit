Import-Module $PSScriptRoot\..\src\GitHubToolKit.psm1 -Force

Describe "Get-GitHubRepos tests" -Tags @("Unit") {

    Context "The GitHub API returns a valid, single page response" {
        Mock Invoke-RestMethod -ModuleName GitHubToolKit -MockWith {
            $Nodes = @(
                New-Object -TypeName PSCustomObject -Property @{ name = "foo-bar-repo" }
                New-Object -TypeName PSCustomObject -Property @{ name = "foo-foo-repo" }
            )
            $PageInfo = New-Object -TypeName PSCustomObject -Property @{ endCursor = "nOTarEALcURSOR=="; hasNextPage = "False" }
            $Repositories = New-Object -TypeName PSCustomObject -Property @{ nodes = $Nodes; pageInfo = $PageInfo }
            $Organization = New-Object -TypeName PSCustomObject -Property @{ repositories = $Repositories }
            $Data = New-Object -TypeName PSCustomObject -Property @{ organization = $Organization }
            $ReturnObject = New-Object -TypeName PSCustomObject -Property @{ data = $Data }
            return $ReturnObject
        }

        It "Should call Invoke-RestMethod once and return an array of repositories and their basic properties" {
            Set-GitHubSessionInformation -PatToken "not-a-real-pat-token"
            $Result = Get-GitHubRepos -GitHubOrg SkillsFundingAgency
            $Result.Count | Should -Be 2
            Assert-MockCalled -CommandName Invoke-RestMethod -ModuleName GitHubToolKit -Times 1 -Exactly
        }
    }
}
