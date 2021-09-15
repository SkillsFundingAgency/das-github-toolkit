Import-Module $PSScriptRoot\..\src\GitHubToolKit.psm1 -Force

Describe "Get-GitHubLicenceInfo tests" -Tags @("Unit") {

    Context "The GitHub API returns a valid, single page response" {
        Mock Invoke-RestMethod -ModuleName GitHubToolKit -MockWith {
            $Licence = New-Object -TypeName PSCustomObject -Property @{ name = "Foo Licence" }
            $Nodes = @(
                New-Object -TypeName PSCustomObject -Property @{ licenseInfo = $null; name = "foo-bar-repo" }
                New-Object -TypeName PSCustomObject -Property @{ licenseInfo = $Licence; name = "foo-foo-repo" }
            )
            $PageInfo = New-Object -TypeName PSCustomObject -Property @{ endCursor = "nOTarEALcURSOR=="; hasNextPage = "False" }
            $Repositories = New-Object -TypeName PSCustomObject -Property @{ nodes = $Nodes; pageInfo = $PageInfo }
            $Organization = New-Object -TypeName PSCustomObject -Property @{ repositories = $Repositories }
            $Data = New-Object -TypeName PSCustomObject -Property @{ organization = $Organization }
            $ReturnObject = New-Object -TypeName PSCustomObject -Property @{ data = $Data }
            return $ReturnObject
        }
        
        It "Should call Invoke-RestMethod once and return the name and licenseInfo.name properties for each repository" {
            Set-GitHubSessionInformation -PatToken "not-a-real-pat-token"
            $Result = Get-GitHubLicenceInfo -GitHubOrg FooOrganisation
            Assert-MockCalled -CommandName Invoke-RestMethod -ModuleName GitHubToolKit -Times 1 -Exactly
            $Result.Count | Should -Be 2
            $Result[0].repoName | Should -Be "foo-bar-repo"
            $Result[0].repoLicence | Should -BeNullOrEmpty
            $Result[1].repoName | Should -Be "foo-foo-repo"
            $Result[1].repoLicence | Should -Be "Foo Licence"
        }
    }
}
