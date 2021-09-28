Import-Module $PSScriptRoot\..\src\GitHubToolKit.psm1 -Force

Describe "Get-GitHubOrgRepoPermissionsByTeam tests" -Tags @("Unit") {

    Context "The GitHub API returns a valid, single page response" {
        Mock Invoke-RestMethod -ModuleName GitHubToolKit -ParameterFilter { $Body -match "{ name teams" } -MockWith {
            $Nodes = @(
                New-Object -TypeName PSCustomObject -Property @{ name = "Foo Team" }
                New-Object -TypeName PSCustomObject -Property @{ name = "Bar Team" }
            )
            $PageInfo = New-Object -TypeName PSCustomObject -Property @{ endCursor = "nOTarEALcURSOR=="; hasNextPage = "False" }
            $Teams = New-Object -TypeName PSCustomObject -Property @{ nodes = $Nodes; pageInfo = $PageInfo }
            $Organization = New-Object -TypeName PSCustomObject -Property @{ teams = $Teams }
            $Data = New-Object -TypeName PSCustomObject -Property @{ organization = $Organization }
            $ReturnObject = New-Object -TypeName PSCustomObject -Property @{ data = $Data }
            return $ReturnObject
        }
        #NOTE: due to a permissions issue the data structure mocked below hasn't been validated against actual returned data
        Mock Invoke-RestMethod -ModuleName GitHubToolKit -ParameterFilter { $Body -match "{ team\(slug" } -MockWith {
            $Node = New-Object -TypeName PSCustomObject -Property @{ name = "foo-bar-repo" }
            $Edges = @(
                New-Object -TypeName PSCustomObject -Property @{ permission = "Write"; node = $Node }
                New-Object -TypeName PSCustomObject -Property @{ permission = "Read"; node = $Node }
            )
            $PageInfo = New-Object -TypeName PSCustomObject -Property @{ endCursor = "nOTarEALcURSOR=="; hasNextPage = "False" }
            $Repositories = New-Object -TypeName PSCustomObject -Property @{ edges = $Edges }
            $Team = New-Object -TypeName PSCustomObject -Property @{ repositories = $Repositories; pageInfo = $PageInfo }
            $Organization = New-Object -TypeName PSCustomObject -Property @{ team = $Team }
            $Data = New-Object -TypeName PSCustomObject -Property @{ organization = $Organization }
            $ReturnObject = New-Object -TypeName PSCustomObject -Property @{ data = $Data }
            return $ReturnObject
        }

        It "Should call Invoke-RestMethod twice and return an array of teams with each team item having another array of repositories" {
            Set-GitHubSessionInformation -PatToken "not-a-real-pat-token"
            $Result = Get-GitHubOrgRepoPermissionsByTeam -GitHubOrg FooOrganisation -RepoSearchString "foo-"
            $Result.Count | Should -Be 2
            { $Result | Select-Object -ExpandProperty teamRepos } | Should -Not -Throw
            Assert-MockCalled -CommandName Invoke-RestMethod -ModuleName GitHubToolKit -Times 3 -Exactly
        }
    }
}
