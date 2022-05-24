function Get-GitHubRepoReleases {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]$GitHubOrganisation,
        [Parameter(Mandatory = $true)]
        [String]$RepositoryName
    )

    $Releases = Invoke-GithubRestMethod -Method GET -Uri "/repos/$GitHubOrganisation/$RepositoryName/releases"

    return $Releases
}

