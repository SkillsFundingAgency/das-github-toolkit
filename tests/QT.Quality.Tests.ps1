$Scripts = Get-ChildItem -Path $PSScriptRoot/.. -File -Include "*.ps1" -Exclude "*Tests.ps1" -Recurse | Where-Object { $_.FullName -inotmatch "[\\|\/]Classes[\\|\/]" }

$ScriptsToExcludeFromDocumentationTests = @("Helpers.ps1", "GitHubToolKit.psm1")

Describe "Script documentation tests" -Tags @("Quality") {

    Import-Module $PSScriptRoot\..\src\GitHubToolKit.psm1 -Force

    foreach ($Script in $Scripts) {
        if ($Script.Name -notin $ScriptsToExcludeFromDocumentationTests) {
            Remove-Variable Help -ErrorAction SilentlyContinue
            # gets help from legacy scripts that do not export a function
            $Help = Get-Help $Script.FullName
            if ($Help.GetType().Name -ne "PSCustomObject" -and $Help.Trim() -eq $Script.Name) {
                $Help = Get-Help ($Script.Name -replace $Script.Extension, "")
            }

            Context $Script.BaseName {

                It "Has a synopsis" {
                    $Help.Synopsis | Should Not BeNullOrEmpty
                }

                It "Has a description" {
                    $Help.Description | Should Not BeNullOrEmpty
                }

                It "Has an example" {
                    $Help.Examples | Should Not BeNullOrEmpty
                }

                foreach ($Parameter in $Help.Parameters.Parameter) {
                    if ($Parameter -notmatch 'whatif|confirm') {
                        It "Has a Parameter description for $($Parameter.Name)" {
                            $Parameter.Description.Text | Should Not BeNullOrEmpty
                        }
                    }
                }
            }
        }
    }
}

Describe "Script code quality tests" -Tags @("Quality") {

    $Rules = Get-ScriptAnalyzerRule
    $ExcludeRules = @(
        "PSAvoidUsingWriteHost",
        "PSAvoidUsingEmptyCatchBlock",
        "PSAvoidUsingPlainTextForPassword"
    )

    foreach ($Script in $Scripts) {
        Context $Script.BaseName {
            forEach ($Rule in $Rules) {
                It "Should pass Script Analyzer rule $Rule" {
                    $Result = Invoke-ScriptAnalyzer -Path $Script.FullName -IncludeRule $Rule -ExcludeRule $ExcludeRules
                    $Result.Count | Should Be 0
                }
            }
        }
    }
}

Describe "Should have a unit test file" -Tags @("Quality") {

    foreach ($Script in $Scripts) {
        $TestName = "$($Script.BaseName).Tests.ps1"
        Context "$($Script.BaseName)" {
            It "Should have an associated unit test called UTxxx.$TestName" {
                $TestFile = Get-Item -Path "$PSScriptRoot/UT*$TestName" -ErrorAction SilentlyContinue
                $TestFile | Should Not Be $null
            }
        }
    }
}
