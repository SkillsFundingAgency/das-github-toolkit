function Get-GithubRepoBranchRef
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]$GitHubOrganisation,
        [Parameter(Mandatory = $true)]
        [String]$RepositoryName,
        [Parameter(Mandatory = $true)]
        [String]$BranchName
    )

    $BranchRef = Invoke-GithubRestMethod -Method GET -Uri "/repos/$GitHubOrganisation/$RepositoryName/git/refs/heads/$BranchName"

    return $BranchRef
}
