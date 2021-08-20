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
Search-DotNetFrameworks -PackageName Microsoft.Extensions.Configuration -GitHubOrganisation MyOrganisation
#>
function Search-DotNetFrameworks {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [String]$GitHubOrganisation = "SkillsFundingAgency",
        [Parameter(Mandatory=$false)]
        [String]$RepositoryPrefix = "das-",
        [Parameter(Mandatory=$false)]
        [String]$CsvOutputPath
    )

    $Repos = Get-GitHubRepos -GitHubOrg $GitHubOrganisation | Where-Object { $_.name -match "^$RepositoryPrefix.+" -and $_.isArchived -eq $False }
    Write-Verbose "Searching $($Repos.Count) repos ..."

    $Files = @()
    $SearchResults = @()
    foreach ($Repo in $Repos) {
        $Files += Invoke-GitHubRestMethod -Method GET $('/search/code?q=org%3A' + $GitHubOrganisation + '+repo%3A' + $GitHubOrganisation +'/' + $Repo.name + '+extension%3Acsproj' + '+Project')
    }

    if (!$Files.total_count) {
        throw "No csproj files retrieved"
    }

    $Files = $Files.items

    foreach ($File in $Files) {
        try {
            $FileContentHeader = @{ Accept = "application/vnd.github.v3.raw" }
            $FileContent = Invoke-GitHubRestMethod -Method GET -Uri "/repos/$GitHubOrganisation/$($File.repository.name)/contents/$($File.path)" -Headers $FileContentHeader
        }
        catch [System.Net.Http.HttpRequestException]{
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
                    $Version = ($VersionString -split '')[1..($Digits-2)] -join '.'
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
                Write-Warning "TargetFramework value $MatchResult in $($File.path) in repository $($File.repository.name) didn't match any known patterns"
            }

            $SearchResult = New-Object -TypeName GitHubDotNetFrameworkSearch -Property @{
                Repository = $File.repository.name
                FrameworkType = $FrameworkType
                Version = $Version
                ConfigFilePath = $File.path
            }
            $SearchResults += $SearchResult
        }
        else {
            Write-Warning "TargetFramework not found in file $($File.path) in repository $($File.repository.name)"
        }
    }

    if($CsvOutputPath) {
        $SearchResults | Export-Csv -Path $CsvOutputPath
    }

    $SearchResults
}
