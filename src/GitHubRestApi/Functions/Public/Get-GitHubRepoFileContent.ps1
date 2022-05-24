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
