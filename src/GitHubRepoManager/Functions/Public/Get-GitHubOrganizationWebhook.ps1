function Get-GitHubOrganizationWebhook {
<#
    .SYNOPSIS
    A PowerShell function for auditing the webhooks in use on a GitHub organisation's repos

    .DESCRIPTION
    A PowerShell function for auditing the webhooks in use on a GitHub organisation's repos.
    Utilises the GitHub API v3

    .PARAMETER Username
    Username of a GitHub user with appropriate permissions within the GitHub organization

    .PARAMETER APIKey
    A PAT token with with full control over repos (to read private repos) and read:repo_hook

    .PARAMETER Organization
    (optional) The GitHub organisation to audit

    .PARAMETER OutputFolder
    (optional) The folder to write the CSV output to

    .EXAMPLE
    .\Get-GitHubOrganizationWebhook.ps1 -UserName MyUserName -APIKey abcd1234

#>
    [CmdletBinding()]
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
        [String]$OutputFolder = "$($env:HOMEDRIVE)$($env:HOMEPATH)\Documents"

    )

    Write-Verbose -Message "Starting GitHub session for user $Username"
    Set-GitHubSessionInformation -Username $Username -APIKey $ApiKey

    $uri = "/orgs/$Organization/repos?type=all"
    $repos = Invoke-GitHubRestMethod -Method GET -Uri $uri
    Write-Verbose -Message "Got $($repos.Length) repositories"

    $report = @()
    foreach ($repo in $repos) {

        Write-Verbose -Message "Getting webhooks for $($repo.name)"
        $uri = "/repos/$Organization/$($repo.name)/hooks"
        $hooks = Invoke-GitHubRestMethod -Method GET -Uri $uri
        Write-Verbose -Message "Got $($hooks.Length) webhooks from $($repo.name)"
        foreach ($hook in $hooks) {

            $item = New-Object PsObject
            $item | Add-Member -MemberType NoteProperty -Name Repo -Value $repo.full_name
            $item | Add-Member -MemberType NoteProperty -Name Service -Value $hook.config.url.Split("/")[2]
            $item | Add-Member -MemberType NoteProperty -Name Events -Value $($hook.events -join ", ")
            $item | Add-Member -MemberType NoteProperty -Name Active -Value $hook.active
            $item | Add-Member -MemberType NoteProperty -Name LastUpdated -Value $hook.updated_at
            $item | Add-Member -MemberType NoteProperty -Name InsecureSsl -Value $hook.config.insecure_ssl
            $item | Add-Member -MemberType NoteProperty -Name ContentType -Value $hook.config.content_type
            $item | Add-Member -MemberType NoteProperty -Name ConfigUrl -Value $hook.config.url
            $report += $item

        }

    }

    Write-Verbose -Message "Output folder set to $OutputFolder"
    $FileName = "$OutputFolder\GitHubOrganizationWebHooks-$Organization-$([DateTime]::Now.ToString("yyyyMMdd-HHmm")).csv"
    try {

        Write-Host "Saving report to $FileName"
        $report | Export-Csv -Path $FileName

    }
    catch [Exception] {
        throw $_.Exception.Message
    }
}

