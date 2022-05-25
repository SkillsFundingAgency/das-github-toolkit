<#

.SYNOPSIS
Updates the refs of the azure-pipelines.yml file's repository resources to the latest

.DESCRIPTION
Updates the refs of the azure-pipelines.yml file's repository resources to the latest

.PARAMETER GitHubOrganisation
The GitHub organisation

.PARAMETER RepositoryPrefix
The prefix of repositories to create new branches with updated pipeline dependencies

.EXAMPLE
Set-GitHubSessionInformation -PatToken <not-a-real-pat-token>
Update-AzurePipelineDependencies -GitHubOrganisation MyOrganisation -RepositoryPrefix foo-

#>
function Update-AzurePipelineDependencies {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "RepoSearchString", Justification = "False positive as rule does not know that Where-Object operates within the same scope")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "")]
    param(
        [Parameter(Mandatory = $false)]
        [String]$GitHubOrganisation = "SkillsFundingAgency",
        [Parameter(Mandatory = $false)]
        [String]$RepositoryPrefix = "das-"
    )

    $Repos = Get-GitHubRepo -GitHubOrg $GitHubOrganisation | Where-Object { $_.name -match "^$RepositoryPrefix.+" -and $_.isArchived -eq $False }

    $Repos | ForEach-Object {
        $Repo = $_

        Write-Host "Scanning $($Repo.name)"

        $PipelineYml = Get-GitHubRepoFileContent -GitHubOrganisation $GitHubOrganisation -RepositoryName $Repo.name -FilePath "azure-pipelines.yml"

        if (!$PipelineYml) { return }

        $Pipeline = ConvertFrom-Yaml -Yaml $PipelineYml.Content

        $Pipeline.resources.repositories | Where-Object { $_.type -eq "github" } | ForEach-Object {
            if ($_.ref -like "refs/tags/*") {
                $TagName = $_.ref.replace("refs/tags/", "")
                $DependencyOrg = $_.name.Split("/")[0]
                $DependencyRepo = $_.name.Split("/")[1]
                $Releases = Get-GitHubRepoRelease -GitHubOrganisation $DependencyOrg -RepositoryName $DependencyRepo
                $OutOfDate = $Releases[0].tag_name -ne $TagName

                if ($OutOfDate) {
                    Write-Warning "$($_.name) dependency: $TagName should be $($Releases[0].tag_name): updating"
                    $PipelineYml.Content = $PipelineYml.Content.Replace($TagName, $Releases[0].tag_name)
                }
                else {
                    Write-Host "$($_.name) dependency up to date" -ForegroundColor Green
                }
            }
            else {
                Write-Warning "No tag reference for: $($_.name) - $($_.ref)"
                return
            }
        }

        $User = Read-Host -Prompt "Commit changes? y/n"

        if ($User -eq 'y') {
            $NewBranchName = "pipeline-dependency-updates"

            $DefaultBranchRef = Get-GithubRepoBranchRef -GitHubOrganisation $GitHubOrganisation -RepositoryName $Repo.name -BranchName $_.defaultBranchRef.name

            New-GitHubRepoBranch -GitHubOrganisation $GitHubOrganisation -RepositoryName $Repo.name `
                -BaseRefSha $DefaultBranchRef.object.sha -NewBranchName $NewBranchName

            $FileContentParams = @{
                GitHubOrganisation = $GitHubOrganisation
                RepositoryName     = $Repo.Name
                BranchName         = $NewBranchName
                FilePath           = "azure-pipelines.yml"
                FileContent        = $PipelineYml.Content
                CommitMessage      = "Updating pipeline dependencies"
                BaseRefSha         = $PipelineYml.Sha
            }
            Set-GitHubRepoFileContent @FileContentParams
        }
    }
}
