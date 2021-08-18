<#
.SYNOPSIS
    A PowerShell function for removing all the webhooks from a repo.
.DESCRIPTION
    A PowerShell function for removing all the webhooks from a repo.
.PARAMETER Username
    Username of a GitHub user with appropriate permissions within the GitHub organization
.PARAMETER APIKey
    A PAT token with with full control over repos (to read private repos) and read:repo_hook
.PARAMETER Organization
    Optional.  The GitHub organisation that contains the repo, if not specified defaults to SkillsFundingAgency
.PARAMETER RepoName
    Required.  The name of the repo 
.EXAMPLE
    Remove-GitHubRepohooks -Username AGitHubUser -ApiToken abc123dfe456hij789 -RepoName AGitHubRepo
.INPUTS
    Inputs to this cmdlet (if any)
.OUTPUTS
    Output from this cmdlet (if any)
.NOTES
    Uses https://developer.github.com/v3/repos/hooks/#delete-a-hook
#>
function Remove-GitHubRepoWebhooks {
    [CmdletBinding(
        SupportsShouldProcess=$true,
        ConfirmImpact='High'
    )]
    [OutputType([String])]
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
        [string]$RepoName

    )
    
    Write-Verbose -Message "Starting GitHub session for user $Username"
    Set-GitHubSessionInformation -Username $Username -APIKey $ApiKey

    $Uri = "/repos/$Organization/$RepoName"
    $Repo = Invoke-GitHubRestMethod -Method GET -Uri $Uri

    if ($Repo.name -eq $RepoName) {
        
        Write-Verbose -Message "Getting webhooks for $($Repo.name)"
        $Uri = "/repos/$Organization/$($Repo.name)/hooks"
        $Hooks = Invoke-GitHubRestMethod -Method GET -Uri $Uri
        Write-Verbose -Message "Got $($Hooks.Length) webhooks from $($Repo.name)"

        foreach ($Hook in $Hooks) {

            $Uri = "/repos/$Organization/$($Repo.name)/hooks/$($Hook.Id)"
            if(!$PSCmdlet.ShouldProcess($($Hook.config.url), "Remove webhook")) {

                Write-Host "Invoking https://api.github.com$Uri to remove webhook $($Hook.config.url)"

            }
            else {

                Write-Verbose "Invoking https://api.github.com$Uri to remove webhook $($Hook.config.url)"
                Invoke-GitHubRestMethod -Method DELETE -Uri $Uri

            }

        }

    }
    else {

        Write-Host "Repository $RepoName not found."

    }

    Write-Host "Removed  $($Hooks.Length) webhooks from $($Repo.name)"

}