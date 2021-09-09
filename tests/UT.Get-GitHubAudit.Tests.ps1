Import-Module $PSScriptRoot\..\src\GitHubToolKit.psm1 -Force

InModuleScope GitHubToolKit {
    Describe "Get-GitHubAudit tests" -Tags @("Unit") {

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
                , $Result | Should -BeOfType System.Array
            }
        }

        Context "GitHub API returns valid responses to all API calls and storage account details are supplied" {
            Mock New-AzStorageContext
            Mock Get-AzStorageContainer -MockWith {
                return New-Object -TypeName PSCustomObject
            }
            Mock New-AzStorageContainer
            Mock Write-Verbose
            Mock Set-AzStorageBlobContent

            It "Returns an array of GitHubRepoAudit objects and writes a json file to blob storage" {
                $Params["StorageAccountName"] = "notarealstorageaccount"
                $Params["StorageAccountKey"] = "bm90LWEtcmVhbC1hY2NvdW50LWtleQ=="

                $Result = Get-GitHubAudit @Params -Verbose
                Assert-MockCalled -CommandName Get-GitHubTeamsAndPermIssionsAudit -ModuleName GitHubToolKit
                Assert-MockCalled -CommandName Get-GitHubBranchProtectionRulesAudit -ModuleName GitHubToolKit
                Assert-MockCalled -CommandName Get-GitHubLicencesAudit -ModuleName GitHubToolKit
                Assert-MockCalled -CommandName Get-AzStorageContainer
                Assert-MockCalled -CommandName New-AzStorageContainer -Times 0
                Assert-MockCalled -CommandName Set-AzStorageBlobContent
                Assert-MockCalled -CommandName Write-Verbose -Times 1 -ParameterFilter { $Message -match "Uploading audit results to blob GitHubAuditResults_\d{8}-\d{4}.json in container github-audit-results of storage account notarealstorageaccount"}
                , $Result | Should -BeOfType System.Array
            }
        }
    
        Context "GitHub API returns valid responses to all API calls but config only selects one repo" {
            It "Returns an array of GitHubRepoAudit objects and writes a json file to blob storage" {
                ##TO DO: identify why causes an error at line 96 if at line 94 only 1 repo is added to $ResultsToReturn
                Mock -ModuleName GitHubToolKit Get-GitHubRepos -MockWith {
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
                $Result = Get-GitHubAudit @Params -Verbose
            }
        }
    
    }
}
