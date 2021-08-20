<#
.SYNOPSIS
Gets all the repos for a specified organisation and writes the output to a CSV file

.DESCRIPTION
Gets all the repos for a specified organisation and writes the output to a CSV file

.PARAMETER Username
GitHub username - possibly deprecated authentication method

.PARAMETER APIKey
GitHub API key - possibly deprecated authentication method

.PARAMETER Organization
(optional) GitHub organisation

.PARAMETER OutputFolder
(optional) folder to write the output file to

.EXAMPLE
Get-GitHubOrganizationRepos -Username MyUserName -APIKey 1234abcd
#>
function Get-GitHubOrganizationRepos {
    param(

        [Parameter(Mandatory=$true, Position=0)]
        [ValidateNotNullOrEmpty()]
        [String]$Username,

        [Parameter(Mandatory=$true, Position=1)]
        [ValidateNotNullOrEmpty()]
        [String]$APIKey,

        [Parameter(Mandatory=$false, Position=2)]
        [String]$Organization = "SkillsFundingAgency",

        [Parameter(Mandatory=$false, Position=3)]
        # Validate that the path doesn't end in backslash
        [ValidatePattern(".*(?<!\\)$")]
        [String]$OutputFolder = "$env:HOMEDRIVE$env:HOMEPATH\Documents"

    )

    Write-Verbose -Message "Starting GitHub session for user $Username"
    Set-GitHubSessionInformation -Username $Username -APIKey $ApiKey

    $uri = "/orgs/$Organization/repos?type=all"
    $repos = Invoke-GitHubRestMethod -Method GET -Uri $uri
    Write-Verbose -Message "Got $($repos.Length) repositories"

    $report = $repos | Select-Object -Property name, has_issues, has_projects, has_wiki, private, @{Label="Licence"; Expression={$_.license.name}}, @{Label="has_desciption"; Expression={$null -ne $_.description}}, @{Label="has_homepage"; Expression={$null -ne $_.homepage}}
    Write-Verbose -Message "Output folder set to $OutputFolder"
    $FileName = "$OutputFolder\GitHubOrganizationRepos-$Organization-$([DateTime]::Now.ToString("yyyyMMdd-HHmm")).csv"
    try {

        Write-Host "Saving report to $FileName"
        $report | Export-Csv -Path $FileName

    }
    catch [Exception] {
        throw $_.Exception.Message
    }

}
