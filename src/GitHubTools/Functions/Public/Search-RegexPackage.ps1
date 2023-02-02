<#
.SYNOPSIS
Searches for csproj files across a GitHub organisation and check if the queried package is referenced.

.DESCRIPTION
Searches for csproj files across a GitHub organisation and check if the queried package is referenced.  Returns a warning where the file cannot be retrieved or the version cannot be parsed.

.PARAMETER GitHubOrganisation
The GitHub organisation to search

.PARAMETER RepositoryPrefix
(optional) Defaults to "das-*"

.PARAMETER CsvOutputPath
(optional) If CSV output is required specify a path to write it to

.PARAMETER PackageName
(required) the target package to find

.NOTES
To search private repositories using the V3 REST API you will need 'repo', ie full control permissions over repos.

.EXAMPLE
Set-GitHubSessionInformation -PatToken <not-a-real-pat-token>
Search-RegexPackage -PackageName Microsoft.Extensions.Configuration
#>
function Search-RegexPackage {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "RepositoryPrefix", Justification = "False positive as rule does not know that Where-Object operates within the same scope")]
    [OutputType([GitHubDotNetFrameworkSearch[]])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [String]$GitHubOrganisation = "SkillsFundingAgency",
        [Parameter(Mandatory = $false)]
        [String]$RepositoryPrefix = "das-",
        [Parameter(Mandatory = $false)]
        [String]$CsvOutputPath,
        [Parameter(Mandatory = $true)]
        [String]$PackageName
    )

    $Repos = Get-GitHubRepo -GitHubOrg $GitHubOrganisation | Where-Object { $_.name -match "^$RepositoryPrefix.+" -and $_.isArchived -eq $False }
    Write-Verbose "Searching $($Repos.Count) repos ..."

    $Files = @()
    $SearchResults = [GitHubDotNetFrameworkSearch[]]@()

    for ($r = 0; $r -lt $Repos.Count; $r++) {
        Write-Progress -Id 1 -Activity "Checking Repos" -Status $Repos[$r].name -PercentComplete ((($r + 1) / ($Repos.Count + 1)) * 100)
        $Files = Invoke-GitHubRestMethod -Method GET $('/search/code?q=org%3A' + $GitHubOrganisation + '+repo%3A' + $GitHubOrganisation + '/' + $Repos[$r].name + '+extension%3Acsproj' + '+Project&per_page=100')

        if (!$Files.total_count) {
            Write-Warning "No csproj files retrieved from $($Repos[$r].name)"
            continue
        }
        $Files = $Files.items

        for ($i = 0; $i -lt $Files.Count; $i++) {
            Write-Progress -Id 2 -ParentId 1 -Activity "Checking Files" -Status $Files[$i].name -PercentComplete ((($i + 1) / ($Files.Count + 1)) * 100)
            try {
                $FileContentHeader = @{ Accept = "application/vnd.github.v3.raw" }
                $FileUri = "/repos/$GitHubOrganisation/$($Files[$i].repository.name)/contents/$($Files[$i].path)"
                $FileContent = Invoke-GitHubRestMethod -Method GET -Uri $FileUri -Headers $FileContentHeader
            }
            catch [System.Net.Http.HttpRequestException] {
                Write-Warning "$($_.Exception.Response.StatusCode) $FileUri"
                continue
            }
            catch {
                throw $_
            }

            if ($FileContent.GetType().Name -eq "XmlDocument") {
                $FileContent = $FileContent.OuterXml
            }

            Remove-Variable -Name Matches -ErrorAction SilentlyContinue
            Remove-Variable -Name Version -ErrorAction SilentlyContinue
            $Pattern = "<PackageReference\sInclude=`"($PackageName.*)`"\sVersion=`"(.*)`"\s/>"
            $null = $FileContent -match $Pattern
            #The below code only returns the first match, if different parts of the package are referenced those are not returned
            if ($Matches) {              
                $SearchResult = New-Object -TypeName GitHubRegexSearch -Property @{
                    Repository     = $Files[$i].repository.name
                    Package        = $Matches[1]
                    Version        = $Matches[2]
                    ConfigFilePath = $Files[$i].path
                }
                $SearchResults += $SearchResult
            }
            else {
                Write-Warning "Target package not found in file $($Files[$i].path) in repository $($Files[$i].repository.name)"
            }
        }
    }

    if ($CsvOutputPath) {
        $SearchResults | Export-Csv -Path $CsvOutputPath
    }

    $SearchResults
}
