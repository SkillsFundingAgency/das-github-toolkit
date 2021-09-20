﻿Import-Module $PSScriptRoot\..\src\GitHubToolKit.psm1 -Force

Describe "Get-GitHubVulnerabilities tests" -Tags @("Unit") {

    Context "The GitHub API returns a valid, single page response" {
        Mock Invoke-RestMethod -ModuleName GitHubToolKit -MockWith {
            $VulnNode = New-Object -TypeName PSCustomObject -Property @{ securityVulnerability = "Vulnerable Foo" }
            $VulnEdge = New-Object -TypeName PSCustomObject -Property @{ node = $VulnNode }
            $VulterabilityAlerts = New-Object -TypeName PSCustomObject -Property @{ edges = $VulnEdge }
            $FooBarNode = New-Object -TypeName PSCustomObject -Property @{ name = "foo-bar-repo"; vulnerabilityAlerts = $VulterabilityAlerts }
            $FooFooNode = New-Object -TypeName PSCustomObject -Property @{ name = "foo-foo-repo"; vulnerabilityAlerts = $VulterabilityAlerts }
            $RepoEdges = @(
                New-Object -TypeName PSCustomObject -Property @{ node = $FooBarNode }
                New-Object -TypeName PSCustomObject -Property @{ node = $FooFooNode }
            )
            $PageInfo = New-Object -TypeName PSCustomObject -Property @{ endCursor = "nOTarEALcURSOR=="; hasNextPage = "False" }
            $Repositories = New-Object -TypeName PSCustomObject -Property @{ edges = $RepoEdges; pageInfo = $PageInfo }
            $Organization = New-Object -TypeName PSCustomObject -Property @{ repositories = $Repositories }
            $Data = New-Object -TypeName PSCustomObject -Property @{ organization = $Organization }
            $ReturnObject = New-Object -TypeName PSCustomObject -Property @{ data = $Data }
            return $ReturnObject
        }
        
        It "Should call Invoke-RestMethod once and return an array of repositories with a child array of vulnerability alerts" {
            Set-GitHubSessionInformation -PatToken "not-a-real-pat-token"
            $Result = Get-GitHubVulnerabilities -GitHubOrg SkillsFundingAgency -RepoSearchString "foo-*"
            $Result | Should -BeOfType String
            ($Result | ConvertFrom-Json).Count | Should -Be 2
            Assert-MockCalled -CommandName Invoke-RestMethod -ModuleName GitHubToolKit -Times 1 -Exactly
        }
    }
}
