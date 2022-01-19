<#
.SYNOPSIS
Searches for csproj files across a GitHub organisation and parses the .NET version from each file.

.DESCRIPTION
Searches for csproj files across a GitHub organisation and parses the .NET version from each file.  Returns a warning where the file cannot be retrieved or the version cannot be parsed.

.PARAMETER GitHubOrganisation
The GitHub organisation to search

.PARAMETER RepositoryPrefix
(optional) Defaults to "das-*"

.PARAMETER CsvOutputPath
(optional) If CSV output is required specify a path to write it to

.NOTES
To search private repositories using the V3 REST API you will need 'repo', ie full control permissions over repos.

.EXAMPLE
Set-GitHubSessionInformation -PatToken <not-a-real-pat-token>
Search-DotNetFramework -PackageName Microsoft.Extensions.Configuration -GitHubOrganisation MyOrganisation
#>
function Search-DotNetFramework {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "RepositoryPrefix", Justification = "False positive as rule does not know that Where-Object operates within the same scope")]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [String]$GitHubOrganisation = "SkillsFundingAgency",
        [Parameter(Mandatory = $false)]
        [String]$RepositoryPrefix = "das-",
        [Parameter(Mandatory = $false)]
        [String]$CsvOutputPath
    )

    $Repos = Get-GitHubRepo -GitHubOrg $GitHubOrganisation | Where-Object { $_.name -match "^$RepositoryPrefix.+" -and $_.isArchived -eq $False }
    Write-Verbose "Searching $($Repos.Count) repos ..."

    $Files = @()
    $SearchResults = @()

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
                $FileContent = Invoke-RestMethod -Uri $Files[$i].html_url.Replace("/blob/", "/raw/")
            }
            catch [System.Net.Http.HttpRequestException] {
                Write-Warning "$($_.Exception.Response.StatusCode) $($Files[$i].path)"
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
            $Pattern = "<TargetFramework\w*>(.*)</TargetFramework\w*>"
            $null = $FileContent -match $Pattern
            if ($Matches) {
                $MatchResult = $Matches[1]
                $FrameworkPattern = "^(v|net)([1-4][\d\.]+)"
                $CorePattern = "(\w{3,})(\d\.\d)"
                if ($MatchResult -match $FrameworkPattern) {
                    $FrameworkType = "framework"
                    $VersionString = $Matches[2]
                    if ($VersionString -match "^\d+$") {
                        Write-Verbose "Parsing framework version from legacy version '$VersionString'"
                        $Digits = ($VersionString -split '').Count
                        $Version = ($VersionString -split '')[1..($Digits - 2)] -join '.'
                    }
                    else {
                        Write-Verbose "Setting framework version to '$VersionString'"
                        $Version = $VersionString
                    }
                }
                elseif ($MatchResult -match $CorePattern) {
                    Write-Verbose "Setting $($Matches[1]) version to '$($Matches[2])'"
                    $FrameworkType = $Matches[1]
                    $Version = $Matches[2]
                }
                else {
                    Write-Warning "TargetFramework value $MatchResult in $($Files[$i].path) in repository $($Files[$i].repository.name) didn't match any known patterns"
                }

                $SearchResult = New-Object -TypeName GitHubDotNetFrameworkSearch -Property @{
                    Repository     = $Files[$i].repository.name
                    FrameworkType  = $FrameworkType
                    Version        = $Version
                    ConfigFilePath = $Files[$i].path
                }
                $SearchResults += $SearchResult
            }
            else {
                Write-Warning "TargetFramework not found in file $($Files[$i].path) in repository $($Files[$i].repository.name)"
            }
        }
    }

    if ($CsvOutputPath) {
        $SearchResults | Export-Csv -Path $CsvOutputPath
    }

    $SearchResults
}
