<#
.SYNOPSIS
    A PowerShell function to add a webhook to a GitHub repo.
.DESCRIPTION
    A PowerShell function to add a webhook to a GitHub repo that implements the create a hook method from https://developer.github.com/v3/repos/hooks/#create-a-hook
.EXAMPLE
    New-GitHubRepoWebhook -Username AGitHubUser -ApiToken abc123dfe456hij789 -RepoName AGitHubRepo  -WebhookUrl https://anothertest.url.com -ContentType json -Events Create, Delete -Secret '$3cret' -Verbose
.OUTPUTS
    An array containing 2 PSObjects - the first holds the session data, the second holds the webhook data
.PARAMETER Username
    Required.  Username of a GitHub user with appropriate permissions within the GitHub organization
.PARAMETER APIKey
    Required.  A PAT token with with full control over repos (to read private repos) and read:repo_hook.PARAMETER 
.PARAMETER Organization
    Optional.  The GitHub organisation that contains the repo, if not specified defaults to SkillsFundingAgency
.PARAMETER RepoName
    Required.  The repository name
.PARAMETER WebhookUrl
    Required.  
.PARAMETER ContentType
    Required.  Either json or form
.PARAMETER Secret
    Optional.  
.PARAMETER Events
    Optional.  Defaults to push.
#>
function New-GitHubRepoWebhook {
    [CmdletBinding(
        SupportsShouldProcess=$true,
        ConfirmImpact='Medium')]
    [OutputType([Array])]
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

        [Parameter(Mandatory=$true, Position=4)]
        [ValidateNotNullOrEmpty()]
        [string]$WebhookUrl,

        [Parameter(Mandatory=$true, Position=5)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("json", "form")]
        [string]$ContentType,

        [Parameter(Mandatory=$false, Position=6)]
        [ValidateNotNullOrEmpty()]
        [string]$Secret,

        [Parameter(Mandatory=$true, Position=7)]
        [ValidateSet("CommitComment", "Create", "Delete", "Deployment", "DeploymentStatus", "Download", "Follow", "Fork", "ForkApply", "Gist", "Gollum", 
            "Installation", "InstallationRepositories", "IssueComment", "Issues", "Label", "MarketplacePurchase", "Member", "Membership", "Milestone", 
            "Organization", "OrgBlock", "PageBuild", "ProjectCard", "ProjectColumn", "Project", "Public", "PullRequest", "PullRequestReview", 
            "PullRequestReviewComment", "Push", "Release", "Repository", "Status", "Team", "TeamAdd", "Watch")]
        [string[]]$Events = "push"

    )    

    Write-Verbose -Message "Starting GitHub session for user $Username"
    Set-GitHubSessionInformation -Username $Username -APIKey $ApiKey

    $Uri = "/repos/$Organization/$RepoName"
    $Repo = Invoke-GitHubRestMethod -Method GET -Uri $Uri

    if ($Repo.name -eq $RepoName) {
    
        $ConfigObject = New-Object psobject
        $ConfigObject | Add-Member -MemberType NoteProperty -Name url -Value $WebhookUrl
        $ConfigObject | Add-Member -MemberType NoteProperty -Name content_type -Value $ContentType
        if($Secret -ne $null -and $Secret -ne "") {
            $ConfigObject | Add-Member -MemberType NoteProperty -Name secret -Value $Secret
        }

        $ParametersObject = New-Object psobject
        $ParametersObject | Add-Member -MemberType NoteProperty -Name name -Value "web"
        $ParametersObject | Add-Member -MemberType NoteProperty -Name active -Value $true
        for ($e = 0; $e -lt $Events.Length; $e++) {
            $Events[$e] = $Events[$e].ToLower()
        }
        $ParametersObject | Add-Member -MemberType NoteProperty -Name events -Value $Events
        $ParametersObject | Add-Member -MemberType NoteProperty -Name config -Value $ConfigObject

        $Uri = "/repos/$Organization/$($Repo.name)/hooks"
        if(!$PSCmdlet.ShouldProcess($($Repo.name), "Add webhook")) {

            Write-Host "Invoking https://api.github.com$Uri to add webhook to $($Repo.name) using parameters:`n $($ParametersObject | ConvertTo-Json)"
        
        }
        else {

            Write-Verbose "Invoking https://api.github.com$Uri to add webhook to $($Repo.name) using parameters:`n $($ParametersObject | ConvertTo-Json)"
            $Result = Invoke-GitHubRestMethod -Method POST -URI $Uri -Body $($ParametersObject | ConvertTo-Json)

        }
    }
    else {

        Write-Host "Repository $RepoName not found."

    }

    ##TO DO: identify which function is adding the GitHubSession information to the output, this happens after the return statement
    return $Result

}