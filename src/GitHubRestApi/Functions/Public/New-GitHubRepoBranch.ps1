function New-GitHubRepoBranch {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]$GitHubOrganisation,
        [Parameter(Mandatory = $true)]
        [String]$RepositoryName,
        [Parameter(Mandatory = $true)]
        [String]$BaseRefSha,
        [Parameter(Mandatory = $true)]
        [String]$NewBranchName
    )

    $CreateBranchParams = @{
        ref = "refs/heads/$NewBranchName"
        sha = $BaseRefSha
    }
    Invoke-GitHubRestMethod -Method POST -Uri "/repos/$GitHubOrganisation/$RepositoryName/git/refs" -Body ($CreateBranchParams | ConvertTo-Json)
}
