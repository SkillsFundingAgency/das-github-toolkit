function New-GitHubRepository {
<#
    .SYNOPSIS
    A PowerShell wrapper for GitHub API create repo method

    .DESCRIPTION
    A PowerShell wrapper for GitHub API create repo method - https://developer.github.com/v3/repos/#create

    .PARAMETER Username
    Username of a GitHub user with appropriate permissions within the GitHub organization

    .PARAMETER APIKey
    A PAT token with with full control over repos

    .PARAMETER Organization
    Optional.  The GitHub organisation that contains the repo, if not specified defaults to SkillsFundingAgency

    .PARAMETER RepoName
    Required. The name of the repository.

    .PARAMETER Description
    Optional. A short description of the repository.

    .PARAMETER Homepage
    Optional. A URL with more information about the repository.

    .PARAMETER Private
    #TO DO: business logic, decide default public / private state of a repo
    Use the Private switch to create a private repository, by default repositories are public.

    .PARAMETER NoIssuesPage
    Use the NoIssuesPage switch to create a repo without an Issues page, by default repositories are created with an Issues page.

    .PARAMETER NoProjectsPage
    Use the NoProjectsPage switch to create a repo without a Projects page, by default repositories are created with a Projects page.

    .PARAMETER NoWiki
    Use the NoWiki switch to create a repo without a Wiki, by default repositories are created with a Wiki.

    .PARAMETER Licence
    Optional.  Specify a licence using the licence keyword, by default the MIT licence is used.
    Other license keywords can be found at https://help.github.com/articles/licensing-a-repository/#searching-github-by-license-type

    .INPUTS
    ##TO DO: decide whether to accept pipeline input

    .OUTPUTS
    System.Management.Automation.PSObject

    .EXAMPLE
    New-GitHubRepository -RepoName "ThisIsATest"

#>
##TO DO: decide on OutputType
[CmdletBinding(DefaultParameterSetName="Standard")][OutputType('System.Management.Automation.PSObject')]

Param (

    [Parameter(Mandatory=$true, Position=0)]
    [ValidateNotNullOrEmpty()]
    [String]$Username,

    [Parameter(Mandatory=$true, Position=1)]
    [ValidateNotNullOrEmpty()]
    [String]$APIKey,

    [Parameter(Mandatory=$false, Position=2)]
    [String]$Organization = "SkillsFundingAgency",

    [Parameter(Mandatory=$true, Position=3)]
    [ValidateNotNullOrEmpty()]
    [string]$RepoName,

    [Parameter(Mandatory=$false, Position=4)]
    [string]$Description,

    [Parameter(Mandatory=$false, Position=5)]
    [string]$Homepage,

    [Parameter(Mandatory=$false, Position=6)]
    [switch]$Private,

    [Parameter(Mandatory=$false, Position=7)]
    [switch]$NoIssuesPage,

    [Parameter(Mandatory=$false, Position=8)]
    [switch]$NoProjectsPage,

    [Parameter(Mandatory=$false, Position=9)]
    [switch]$NoWiki,

    ##TO DO: decide whether to / how to set team_id
    ##TO DO: observe impact of auto_init
    ##TO DO: decide whether to add a gitignore_template

    ##TO DO: dynamically populate from https://developer.github.com/v3/licenses/#list-all-licenses
    [Parameter(Mandatory=$false, Position=10)]
    [string]$Licence = "mit",

    ##TO DO: decide whether to allow_squash\merge\rebase

    [Parameter(Mandatory=$false, Position=11)]
    [string]$WithoutStandardConfig

)

    Write-Verbose -Message "Starting GitHub session for user $Username"
    Set-GitHubSessionInformation -Username $Username -APIKey $ApiKey

    $RepoSettings = New-Object psobject

    $RepoSettings | Add-Member -MemberType NoteProperty -Name name -Value $RepoName
    ##TO DO: test what an empty string description looks like vs no description API parameter
    $RepoSettings | Add-Member -MemberType NoteProperty -Name description -Value $Description
    $RepoSettings | Add-Member -MemberType NoteProperty -Name homepage -Value $Homepage
    $RepoSettings | Add-Member -MemberType NoteProperty -Name private -Value $Private.IsPresent
    if(!$NoIssuesPage.IsPresent) {
        $RepoSettings | Add-Member -MemberType NoteProperty -Name has_issues -Value $true
    }
    if(!$NoProjectsPage.IsPresent) {
        $RepoSettings | Add-Member -MemberType NoteProperty -Name has_projects -Value $true
    }
    if(!$NoWiki.IsPresent) {
        $RepoSettings | Add-Member -MemberType NoteProperty -Name has_wiki -Value $true
    }
    $RepoSettings | Add-Member -MemberType NoteProperty -Name licence_template -Value $Licence

    ##TO DO: replace Write-Verbose with Write-Log
    Write-Verbose -Message $($RepoSettings | ConvertTo-Json)

    ##TO DO: refactor relevant GitHubReleaseModule functions into a GitHubCore module.  Ensure that the session info can be used in modules calling GitHubCore
    ##TO DO: replace URI with /orgs/SkillsFundingAgency/repos after testing

    $Result = Invoke-GitHubRestMethod -Method POST -URI "/user/repos"  -Body ($RepoSettings | ConvertTo-Json)

    if($WithoutStandardConfig.IsPresent -and $Result.name -eq $RepoName) {
        ##Slack Webhook
        ##TO DO: identify correct webhook to use
        #New-GitHubRepoWebhook -Username $Username -APIKey $APIKey -RepoName $Repo.Name -WebhookUrl "https://hooks.slack.com/services/" -ContentType json -Events
    }

    return $Result
}
