Describe "Invoke-DotSourceFiles tests" -Tags @("Unit") {

    Context "Script is executed outside of module" {
        It "Should load all classes and functions" {
            { . $PSScriptRoot\..\src\Invoke-DotSourceFiles.ps1 } | Should -Not -Throw
        }
    }
}
