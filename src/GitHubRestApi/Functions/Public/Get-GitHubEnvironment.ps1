<#
.SYNOPSIS
Gets a list of GitHub environments associated with a specified GitHub repo

.DESCRIPTION
Gets a list of GitHub environments associated with a specified GitHub repo

.PARAMETER GitHubOrg
The GitHub organsation the repo belongs to

.PARAMETER GitHubRepo
The name of the repo to get the environments from

.EXAMPLE
Set-GitHubSessionInformation -PatToken <not-a-real-pat-token>
Get-GitHubEnvironment -GitHubOrg my-org -GitHubRepo my-repo
#>
function Get-GitHubEnvironment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$GitHubOrg,
        [Parameter(Mandatory=$true)]
        [string]$GitHubRepo
    )

    $Environments = Invoke-GitHubRestMethod -Method GET -URI "/repos/$GitHubOrg/$GitHubRepo/environments" -CollectionName environments

    $Environments.environments
}
