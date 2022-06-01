<#

.SYNOPSIS
Deletes a specified branch of a specified repository.
This deletion also closes any pull requests that were open with the branch as origin or target branch.

.DESCRIPTION
Deletes a specified branch of a specified repository.
This deletion also closes any pull requests that were open with the branch as origin or target branch.

.PARAMETER GitHubOrganisation
The GitHub organisation

.PARAMETER RepositoryName
The repository of the GitHub organisation

.PARAMETER BranchName
The name of the branch being deleted


.EXAMPLE
Set-GitHubSessionInformation -PatToken <not-a-real-pat-token>
Remove-GitHubRepoBranch -GitHubOrganisation MyOrganisation -RepositoryName MyRepository -BranchName MyBranchToBeDeleted

.NOTES
The documentation for the GitHub endpoint used by this function can be found here:
https://docs.github.com/en/rest/git/refs#delete-a-reference

#>
function Remove-GitHubRepoBranch {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [String]$GitHubOrganisation,
        [Parameter(Mandatory = $true)]
        [String]$RepositoryName,
        [Parameter(Mandatory = $true)]
        [String]$BranchName,
        [Parameter(Mandatory = $false)]
        [bool]$DryRun = $true
    )

    $RequestUrl = "/repos/$GitHubOrganisation/$RepositoryName/git/refs/heads/$BranchName"

    if ($DryRun) {
        Write-Warning "DryRun: Would be running DELETE $RequestUrl"
    }
    else {
        Write-Host "Deleting branch $BranchName from $GitHubOrganisation/$RepositoryName"
        if ($PSCmdlet.ShouldProcess("$GitHubOrganisation/$RepositoryName/$BranchName")) {
            $null = Invoke-GitHubRestMethod -Method DELETE -Uri $RequestUrl
        }
    }
}
