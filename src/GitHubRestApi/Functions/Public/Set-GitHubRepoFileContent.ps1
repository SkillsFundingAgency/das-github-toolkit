<#

.SYNOPSIS
Sets the content of a specified file in a specified repository

.DESCRIPTION
Sets the content of a specified file in a specified repository

.PARAMETER GitHubOrganisation
The GitHub organisation

.PARAMETER RepositoryName
The repository of the GitHub organisation

.PARAMETER BranchName
The name of the branch in the repository

.PARAMETER FilePath
The file path of the file that is having content set

.PARAMETER FileContent
The Base64 content that the specified file will have

.PARAMETER CommitMessage
The message of the commit for the file change

.PARAMETER BaseRefSha
The blob SHA of the file being replaced

.EXAMPLE
Set-GitHubSessionInformation -PatToken <not-a-real-pat-token>
Set-GithubRepoFileContent -GitHubOrganisation MyOrganisation -RepositoryName MyRepository -BranchName MyBranch -FilePath ./folderA/fileB.yml -FileContent hdfbhjasdft67t -CommitMessage "Updated ./folderA/fileB.yml" -BaseRefSha bf493c4131ac993627ca902aa5b88953690ee833

.NOTES
The documentation for the GitHub endpoint used by this function can be found here:
https://docs.github.com/en/rest/repos/contents#create-or-update-file-contents

#>
function Set-GitHubRepoFileContent {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
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
