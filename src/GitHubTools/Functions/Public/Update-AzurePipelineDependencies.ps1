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

.NOTES
powershell-yaml powershell module is required. Install-Module -name powershell-yaml
The powershell-yaml module is no longer being maintained https://github.com/aaubry/YamlDotNet/discussions/689

#>
function Update-AzurePipelineDependencies {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "RepositoryPrefix", Justification = "False positive as rule does not know that Where-Object operates within the same scope")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "UpdatePipelineYml", Justification="False positive as rule does not know that variable is updated in ForEach-Object")]
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

        $UpdatePipelineYml = $false
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
                    $UpdatePipelineYml = $true
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

        $PipelineYml.Content = $PipelineYml.Content.Replace("      - template: azure-pipelines-templates/build/step/dependency-check.yml@das-platform-building-blocks", "")

        $CodeBuildYml = Get-GitHubRepoFileContent -GitHubOrganisation $GitHubOrganisation -RepositoryName $Repo.name -FilePath "pipeline-templates/job/code-build.yml"

        $UpdateCodeBuildYml = $false
        if ($CodeBuildYml) {
            if ($CodeBuildYml.Content.Contains("  - template: azure-pipelines-templates/build/step/dependency-check.yml@das-platform-building-blocks")) {
                $CodeBuildYml.Content = $CodeBuildYml.Content.Replace("  - template: azure-pipelines-templates/build/step/dependency-check.yml@das-platform-building-blocks", "")
                $UpdateCodeBuildYml = $true
            }
        }
        if ($UpdatePipelineYml || $UpdateCodeBuildYml) {
            $NewBranchName = "pipeline-dependency-updates-" + (Get-Date -Format "FileDate")

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

            if ($UpdateCodeBuildYml) {
                $CodeBuildYml.Content
                $FileContentParams = @{
                    GitHubOrganisation = $GitHubOrganisation
                    RepositoryName     = $Repo.Name
                    BranchName         = $NewBranchName
                    FilePath           = "pipeline-templates/job/code-build.yml"
                    FileContent        = $CodeBuildYml.Content
                    CommitMessage      = "Removing dependency-check template task"
                    BaseRefSha         = $CodeBuildYml.Sha
                }
                Set-GitHubRepoFileContent @FileContentParams
            }
        }
    }
}
