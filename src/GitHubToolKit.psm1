$Scripts = . $PSScriptRoot\Invoke-DotSourceFiles.ps1
Export-ModuleMember -Function $($Scripts | Select-Object -ExpandProperty BaseName) -Verbose:$VerbosePreference
