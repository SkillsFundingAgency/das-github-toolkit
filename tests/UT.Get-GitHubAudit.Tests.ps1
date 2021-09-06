##TO DO: create test config file

Describe "Get-GitHubAudit tests" -Tags @("Unit") {

    Import-Module $PSScriptRoot\..\src\GitHubToolKit.psm1 -Force

    Mock -ModuleName GitHubToolKit Get-GitHubRepos -MockWith {
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
            },
            @{
                name = "bar-foo-repo"
                isArchived = $true
                isPrivate = $false
            }
        )
    }
    Mock -ModuleName GitHubToolKit Get-GitHubTeamsAndPermIssionsAudit -MockWith {
        ##TO DO: consider defining these objects in variables and appending extra properties to avoid duplication
        return @(
            @{
                RepositoryName = "foo-bar-repo"
                IsArchived = $false
                IsPrivateRepository = $true
                AccessControlLIst = @{
                    ExpectedValue = New-Object -TypeName PSCustomObject
                    ActualValue = New-Object -TypeName PSCustomObject
                    CorrectConfiguration = $true
                }
            },
            @{
                RepositoryName = "foo-foo-repo"
                IsArchived = $false
                IsPrivateRepository = $true
                AccessControlLIst = @{
                    ExpectedValue = New-Object -TypeName PSCustomObject
                    ActualValue = New-Object -TypeName PSCustomObject
                    CorrectConfiguration = $true
                }
            },
            @{
                RepositoryName = "bar-foo-repo"
                IsArchived = $true
                IsPrivateRepository = $false
                AccessControlLIst = @{
                    ExpectedValue = New-Object -TypeName PSCustomObject
                    ActualValue = New-Object -TypeName PSCustomObject
                    CorrectConfiguration = $false
                }
            }
        )
    } 
    Mock -ModuleName GitHubToolKit Get-GitHubBranchProtectionRulesAudit -MockWith {
        return @(
            @{
                RepositoryName = "foo-bar-repo"
                IsArchived = $false
                IsPrivateRepository = $true
                AccessControlLIst = @{
                    ExpectedValue = New-Object -TypeName PSCustomObject
                    ActualValue = New-Object -TypeName PSCustomObject
                    CorrectConfiguration = $true
                }
                BranchProtection =@{
                    ExpectedValue = New-Object -TypeName PSCustomObject
                    ActualValue = New-Object -TypeName PSCustomObject
                    CorrectConfiguration = $false
                }
            },
            @{
                RepositoryName = "foo-foo-repo"
                IsArchived = $false
                IsPrivateRepository = $true
                AccessControlLIst = @{
                    ExpectedValue = New-Object -TypeName PSCustomObject
                    ActualValue = New-Object -TypeName PSCustomObject
                    CorrectConfiguration = $true
                }
                BranchProtection =@{
                    ExpectedValue = New-Object -TypeName PSCustomObject
                    ActualValue = New-Object -TypeName PSCustomObject
                    CorrectConfiguration = $false
                }
            },
            @{
                RepositoryName = "bar-foo-repo"
                IsArchived = $true
                IsPrivateRepository = $false
                AccessControlLIst = @{
                    ExpectedValue = New-Object -TypeName PSCustomObject
                    ActualValue = New-Object -TypeName PSCustomObject
                    CorrectConfiguration = $false
                }
                BranchProtection =@{
                    ExpectedValue = New-Object -TypeName PSCustomObject
                    ActualValue = New-Object -TypeName PSCustomObject
                    CorrectConfiguration = $true
                }
            }
        )
    } 
    Mock -ModuleName GitHubToolKit Get-GitHubLicencesAudit -MockWith {
        return @(
            @{
                RepositoryName = "foo-bar-repo"
                IsArchived = $false
                IsPrivateRepository = $true
                AccessControlLIst = @{
                    ExpectedValue = New-Object -TypeName PSCustomObject
                    ActualValue = New-Object -TypeName PSCustomObject
                    CorrectConfiguration = $true
                }
                BranchProtection =@{
                    ExpectedValue = New-Object -TypeName PSCustomObject
                    ActualValue = New-Object -TypeName PSCustomObject
                    CorrectConfiguration = $false
                }
                Licence = @{
                    ExpectedValue = "Foo Licence"
                    ActualValue = "Foo Licence"
                    CorrectConfiguration = $true
                }
            },
            @{
                RepositoryName = "foo-foo-repo"
                IsArchived = $false
                IsPrivateRepository = $true
                AccessControlLIst = @{
                    ExpectedValue = New-Object -TypeName PSCustomObject
                    ActualValue = New-Object -TypeName PSCustomObject
                    CorrectConfiguration = $true
                }
                BranchProtection =@{
                    ExpectedValue = New-Object -TypeName PSCustomObject
                    ActualValue = New-Object -TypeName PSCustomObject
                    CorrectConfiguration = $false
                }
                Licence = @{
                    ExpectedValue = "Foo Licence"
                    ActualValue = "Foo Licence"
                    CorrectConfiguration = $true
                }
            },
            @{
                RepositoryName = "bar-foo-repo"
                IsArchived = $true
                IsPrivateRepository = $false
                AccessControlLIst = @{
                    ExpectedValue = New-Object -TypeName PSCustomObject
                    ActualValue = New-Object -TypeName PSCustomObject
                    CorrectConfiguration = $false
                }
                BranchProtection =@{
                    ExpectedValue = New-Object -TypeName PSCustomObject
                    ActualValue = New-Object -TypeName PSCustomObject
                    CorrectConfiguration = $true
                }
                Licence = @{
                    ExpectedValue = "Foo Licence"
                    ActualValue = "Bar Licence"
                    CorrectConfiguration = $false
                }
            }
        )
    }

    $Params = @{
        PatToken = "not-a-real-pat-token"
        PathToConfigFile = "$PSScriptRoot\test-config.json"
    }

    Context "GitHub API returns valid responses to all API calls and storage account details are not supplied" {
        It "Returns an array of GitHubRepoAudit objects" {
            $Result = Get-GitHubAudit @Params -Verbose
            Assert-MockCalled -CommandName Get-GitHubTeamsAndPermIssionsAudit -ModuleName GitHubToolKit
            Assert-MockCalled -CommandName Get-GitHubBranchProtectionRulesAudit -ModuleName GitHubToolKit
            Assert-MockCalled -CommandName Get-GitHubLicencesAudit -ModuleName GitHubToolKit
            , $Result | Should -BeOfType System.Array
        }
    }

    Context "GitHub API returns valid responses to all API calls and storage account details are supplied" {
        It "Returns an array of GitHubRepoAudit objects and writes a json file to blob storage" {
            ##TO DO:
            ### regex test of file RepositoryName
        }
    }

    Context "GitHub API returns valid responses to all API calls but config only selects one repo" {
        It "Returns an array of GitHubRepoAudit objects and writes a json file to blob storage" {
            ##TO DO: identify why causes an error at line 96 if at line 94 only 1 repo is added to $ResultsToReturn
        }
    }

}