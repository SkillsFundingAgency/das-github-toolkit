Import-Module $PSScriptRoot\..\src\GitHubToolKit.psm1 -Force

Describe "Get-GitHubAudit tests" -Tags @("Unit") {

    Mock -ModuleName GitHubToolKit Get-GitHubRepo -MockWith {
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
        $FooBarAudit = New-Object -TypeName GitHubRepoAudit -Property @{
            RepositoryName = "foo-bar-repo"
            IsArchived = $false
            IsPrivateRepository = $true
            AccessControlLIst = @{
                ExpectedValue = New-Object -TypeName PSCustomObject
                ActualValue = New-Object -TypeName PSCustomObject
                CorrectConfiguration = $true
            }
        }
        $FooFooAudit = New-Object -TypeName GitHubRepoAudit -Property @{
            RepositoryName = "foo-foo-repo"
            IsArchived = $false
            IsPrivateRepository = $true
            AccessControlLIst = @{
                ExpectedValue = New-Object -TypeName PSCustomObject
                ActualValue = New-Object -TypeName PSCustomObject
                CorrectConfiguration = $true
            }
        }
        $BarFooAudit = New-Object -TypeName GitHubRepoAudit -Property @{
            RepositoryName = "bar-foo-repo"
            IsArchived = $true
            IsPrivateRepository = $false
            AccessControlLIst = @{
                ExpectedValue = New-Object -TypeName PSCustomObject
                ActualValue = New-Object -TypeName PSCustomObject
                CorrectConfiguration = $false
            }
        }
        return @(
            $FooBarAudit
            $FooFooAudit
            $BarFooAudit
        )
    }
    Mock -ModuleName GitHubToolKit Get-GitHubBranchProtectionRulesAudit -MockWith {
        $FooBarAudit = New-Object -TypeName GitHubRepoAudit -Property @{
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
        }
        $FooFooAudit = New-Object -TypeName GitHubRepoAudit -Property @{
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
        }
        $BarFooAudit = New-Object -TypeName GitHubRepoAudit -Property @{
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
        return @(
            $FooBarAudit
            $FooFooAudit
            $BarFooAudit
        )
    }
    Mock -ModuleName GitHubToolKit Get-GitHubLicencesAudit -MockWith {
        $FooBarAudit = New-Object -TypeName GitHubRepoAudit -Property @{
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
        }
        $FooFooAudit = New-Object -TypeName GitHubRepoAudit -Property @{
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
        }
        $BarFooAudit = New-Object -TypeName GitHubRepoAudit -Property @{
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
        return @(
            $FooBarAudit
            $FooFooAudit
            $BarFooAudit
        )
    }

    BeforeEach {
        $Params = @{
            PatToken = "not-a-real-pat-token"
            PathToConfigFile = "$PSScriptRoot\test-config.json"
        }
    }

    Context "GitHub API returns valid responses to all API calls and storage account details are not supplied" {
        It "Returns an array of GitHubRepoAudit objects" {
            $Result = Get-GitHubAudit @Params -Verbose
            Assert-MockCalled -CommandName Get-GitHubTeamsAndPermIssionsAudit -ModuleName GitHubToolKit
            Assert-MockCalled -CommandName Get-GitHubBranchProtectionRulesAudit -ModuleName GitHubToolKit
            Assert-MockCalled -CommandName Get-GitHubLicencesAudit -ModuleName GitHubToolKit
            $Result.Count | Should -Be 3
            $Result[0].GetType().Name | Should -Be "GitHubRepoAudit"
        }
    }

    Context "GitHub API returns valid responses to all API calls and storage account details are supplied" {

        #Declare cmdlets as functions so Az PowerShell module is not needed for running unit tests
        function New-AzStorageContext {}
        function Get-AzStorageContainer {}
        function New-AzStorageContainer {}
        function Set-AzStorageBlobContent {}

        Mock New-AzStorageContext -ModuleName GitHubToolKit
        Mock Get-AzStorageContainer -MockWith {
            return New-Object -TypeName PSCustomObject
        } -ModuleName GitHubToolKit
        Mock New-AzStorageContainer -ModuleName GitHubToolKit
        Mock Write-Verbose -ModuleName GitHubToolKit
        Mock Set-AzStorageBlobContent -ModuleName GitHubToolKit

        It "Returns an array of GitHubRepoAudit objects and writes a json file to blob storage" {
            $Params["StorageAccountName"] = "notarealstorageaccount"
            $Params["StorageAccountKey"] = "bm90LWEtcmVhbC1hY2NvdW50LWtleQ=="

            $Result = Get-GitHubAudit @Params -Verbose
            Assert-MockCalled -CommandName Get-GitHubTeamsAndPermIssionsAudit -ModuleName GitHubToolKit
            Assert-MockCalled -CommandName Get-GitHubBranchProtectionRulesAudit -ModuleName GitHubToolKit
            Assert-MockCalled -CommandName Get-GitHubLicencesAudit -ModuleName GitHubToolKit
            Assert-MockCalled -CommandName Get-AzStorageContainer -ModuleName GitHubToolKit
            Assert-MockCalled -CommandName New-AzStorageContainer -ModuleName GitHubToolKit -Times 0
            Assert-MockCalled -CommandName Set-AzStorageBlobContent -ModuleName GitHubToolKit
            Assert-MockCalled -CommandName Write-Verbose -ModuleName GitHubToolKit -Times 1 -ParameterFilter { $Message -match "Uploading audit results to blob GitHubAuditResults_\d{8}-\d{4}.json in container github-audit-results of storage account notarealstorageaccount"}
            $Result.Count | Should -Be 3
            $Result[0].GetType().Name | Should -Be "GitHubRepoAudit"
        }
    }

    Context "GitHub API returns valid responses to all API calls but config only selects one repo" {
        It "Returns an array of GitHubRepoAudit objects and writes a json file to blob storage" {
            Mock -ModuleName GitHubToolKit Get-GitHubRepo -MockWith {
                return @(
                    @{
                        name = "foo-bar-repo"
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
                $FooBarAudit = New-Object -TypeName GitHubRepoAudit -Property @{
                    RepositoryName = "foo-bar-repo"
                    IsArchived = $false
                    IsPrivateRepository = $true
                    AccessControlLIst = @{
                        ExpectedValue = New-Object -TypeName PSCustomObject
                        ActualValue = New-Object -TypeName PSCustomObject
                        CorrectConfiguration = $true
                    }
                }
                $FooFooAudit = New-Object -TypeName GitHubRepoAudit -Property @{
                    RepositoryName = "bar-foo-repo"
                    IsArchived = $true
                    IsPrivateRepository = $false
                    AccessControlLIst = @{
                        ExpectedValue = New-Object -TypeName PSCustomObject
                        ActualValue = New-Object -TypeName PSCustomObject
                        CorrectConfiguration = $false
                    }
                }
                return @(
                    $FooBarAudit
                    $FooFooAudit
                )
            }
            Mock -ModuleName GitHubToolKit Get-GitHubBranchProtectionRulesAudit -MockWith {
                $FooBarAudit = New-Object -TypeName GitHubRepoAudit -Property @{
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
                }
                $FooFooAudit = New-Object -TypeName GitHubRepoAudit -Property @{
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
                return @(
                    $FooBarAudit
                    $FooFooAudit
                )
            }
            Mock -ModuleName GitHubToolKit Get-GitHubLicencesAudit -MockWith {
                $FooBarAudit = New-Object -TypeName GitHubRepoAudit -Property @{
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
                }
                $FooFooAudit = New-Object -TypeName GitHubRepoAudit -Property @{
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
                return @(
                    $FooBarAudit
                    $FooFooAudit
                )
            }

            $Result = Get-GitHubAudit @Params -Verbose
            $Result.Count | Should -Be 2
            $Result[0].GetType().Name | Should -Be "GitHubRepoAudit"
        }
    }
}

