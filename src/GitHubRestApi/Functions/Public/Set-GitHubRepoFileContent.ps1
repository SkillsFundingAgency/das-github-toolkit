function Set-GitHubRepoFileContent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]$GitHubOrganisation,
        [Parameter(Mandatory = $true)]
        [String]$RepositoryName,
        [Parameter(Mandatory = $true)]
        [String]$BranchName,
        [Parameter(Mandatory = $true)]
        [String]$FilePath,
        [Parameter(Mandatory = $true)]
        [String]$FileContent,
        [Parameter(Mandatory = $true)]
        [String]$CommitMessage,
        [Parameter(Mandatory = $true)]
        [String]$BaseRefSha
    )

    $ContentBase64 = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(($FileContent)))

    $PutContents = @{
        message = $CommitMessage
        content = $ContentBase64
        sha     = $BaseRefSha
        branch  = $BranchName
    }
    Invoke-GitHubRestMethod -Method PUT -Uri "/repos/$GitHubOrganisation/$RepositoryName/contents/$FilePath" `
        -Body ($PutContents | ConvertTo-Json)

}
