$Scripts = Get-ChildItem -Path $PSScriptRoot/.. -File -Include "*.ps1" -Exclude "*Tests.ps1", "IT.Mocks.ps1" -Recurse | Where-Object { $_.FullName -inotmatch "[\\|\/]Classes[\\|\/]" }

$ScriptsToExcludeFromDocumentationTests = @("GitHubToolKit.psm1", "Helpers.ps1")

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
        Context "$($Script.BaseName) script" {
            It "Should have an associated unit test called UTxxx.$TestName" {
                $TestFile = Get-Item -Path "$PSScriptRoot/UT*$TestName" -ErrorAction SilentlyContinue
                $TestFile | Should Not Be $null
            }
        }
    }
}

Describe "Integration tests should have a common set of mocks" -Tags @("Quality") {
    $TestScripts = Get-ChildItem -Path $PSScriptRoot -File -Exclude "IT.Mocks.ps1" -Recurse
    foreach ($Script in $TestScripts) {
        Remove-Variable -Name Matches -ErrorAction SilentlyContinue
        $Content = Get-Content -Path $Script.FullName -Raw | Out-String
        # match the Describe block(s) and subsequent line
        $DescribeBlocks = $Content | Select-String '(?m)^Describe(.*)-Tags @\((.*)\) {[\r]?\n(.*)' -AllMatches
        foreach ($DescribeBlock in $DescribeBlocks.Matches) {
            if ($DescribeBlock.Groups["2"].Value -eq '"Integration"') {
                Context "$($DescribeBlock.Groups["1"].Value) describe block of $($Script.BaseName)" {
                    It "Should dot source IT.Mocks.ps1 on the line after the Describe block" {
                        $DescribeBlock.Groups["3"].Value -match '\. \$PSScriptRoot\\IT\.Mocks\.ps1' | Should -BeTrue
                    }
                }
            }
        }


    }
}
