<#

.SYNOPSIS
Gets the content of a specified file for a specified repository

.DESCRIPTION
Gets the content of a specified file for a specified repository

.PARAMETER GitHubOrganisation
The GitHub organisation

.PARAMETER RepositoryName
The repository of the GitHub organisation

.PARAMETER FilePath
The path to the file in the repository to retrieve content

.EXAMPLE
Set-GitHubSessionInformation -PatToken <not-a-real-pat-token>
Get-GitHubRepoFileContent -GitHubOrganisation MyOrganisation -RepositoryName MyRepository -FilePath ./folderA/fileB.yml

.NOTES
The documentation for the GitHub endpoint used by this function can be found here:
https://docs.github.com/en/rest/repos/contents#get-repository-content

#>
function Get-GitHubRepoFileContent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]$GitHubOrganisation,
        [Parameter(Mandatory = $true)]
        [String]$RepositoryName,
        [Parameter(Mandatory = $true)]
        [String]$FilePath
    )


    try {
        $FileObject = Invoke-GitHubRestMethod -Method GET -URI "/repos/$GitHubOrganisation/$RepositoryName/contents/$FilePath"
        $FileContent = [GitHubRepoFile]@{
            Sha = $FileObject.sha
            Content = [System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String($FileObject.content))
        }
        return $FileContent
    }
    catch {
        if ($_.Exception.Response.StatusCode.value__ -eq 404) {
            Write-Warning "Pipeline file $FilePath not found for $GitHubOrganisation/$RepositoryName"
            return $null
        }
        else {
            throw $_
        }
    }
}
