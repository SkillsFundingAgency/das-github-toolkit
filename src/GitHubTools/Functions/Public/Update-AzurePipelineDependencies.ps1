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
The powershell-yaml module and the .NET library the module wraps around is no longer being maintained https://github.com/aaubry/YamlDotNet/discussions/689

#>
function Update-AzurePipelineDependencies {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "RepositoryPrefix", Justification = "False positive as rule does not know that Where-Object operates within the same scope")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Justification = "Script creates and maintains GitHub Pull Requests to update dependencies of pipeline files and is limited to this scope with specific branch name prefixes")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "")]
    param(
        [Parameter(Mandatory = $false)]
        [String]$GitHubOrganisation = "SkillsFundingAgency",
        [Parameter(Mandatory = $false)]
        [String]$RepositoryPrefix = "das-"
    )

    $Repos = Get-GitHubRepo -GitHubOrg $GitHubOrganisation | Where-Object { $_.name -match "^$RepositoryPrefix.+" -and $_.isArchived -eq $False }

    $PullRequestUrls = @()

    foreach ($Repo in $Repos) {

        Write-Host "Scanning $($Repo.name)"

        $PipelineYml = Get-GitHubRepoFileContent -GitHubOrganisation $GitHubOrganisation -RepositoryName $Repo.name -FilePath "azure-pipelines.yml"

        if (!$PipelineYml) {
            Write-Warning "No azure-pipelines.yml retrieved"
            continue
        }

        $Pipeline = ConvertFrom-Yaml -Yaml $PipelineYml.Content

        $UpdatePipelineYml = $false
        $PipelineRepos = $Pipeline.resources.repositories`
        | Where-Object { ($_.type -eq "github") }
        | Where-Object { ($_.name -eq "SkillsFundingAgency/das-platform-building-blocks" -or $_.name -eq "SkillsFundingAgency/das-platform-automation") }
        $NewBranchName = "pipeline-dependencies/"
        $PullRequestTitle = "Updating pipeline dependencies: "
        foreach ($PipelineRepo in $PipelineRepos) {
            if ($PipelineRepo.ref -like "refs/tags/*") {
                $TagName = $PipelineRepo.ref.replace("refs/tags/", "")
                $DependencyOrg = $PipelineRepo.name.Split("/")[0]
                $DependencyRepo = $PipelineRepo.name.Split("/")[1]
                $Releases = Get-GitHubRepoRelease -GitHubOrganisation $DependencyOrg -RepositoryName $DependencyRepo
                $OutOfDate = $Releases[0].tag_name -ne $TagName

                if ($OutOfDate) {
                    Write-Warning "$($PipelineRepo.name) dependency: $TagName should be $($Releases[0].tag_name): updating if an up-to-date PR does not exist"
                    $PipelineYml.Content = $PipelineYml.Content.Replace($TagName, $Releases[0].tag_name)
                    $NewBranchName += "$($DependencyRepo)-$($Releases[0].tag_name)-"
                    $PullRequestTitle += "$($DependencyRepo) to $($Releases[0].tag_name) and "
                    $UpdatePipelineYml = $true
                }
                else {
                    Write-Host "$($PipelineRepo.name) dependency up to date" -ForegroundColor Green
                }
            }
            else {
                Write-Warning "No tag reference for: $($PipelineRepo.name) - $($PipelineRepo.ref)"
                continue
            }
        }

        $DependencyCheckLineInAzurePipelines = "      - template: azure-pipelines-templates/build/step/dependency-check.yml@das-platform-building-blocks"
        $DependencyCheckLineInAzurePipelinesWithSpace = "\n$($DependencyCheckLineInAzurePipelines)\r\n"

        $DependencyCheckLineInCodeBuild = "  - template: azure-pipelines-templates/build/step/dependency-check.yml@das-platform-building-blocks"
        $DependencyCheckLineInCodeBuildWithSpace = "\n$($DependencyCheckLineInCodeBuild)\r\n"

        if ($PipelineYml.Content -match $DependencyCheckLineInAzurePipelinesWithSpace) {
            $PipelineYml.Content = $PipelineYml.Content -replace ($DependencyCheckLineInAzurePipelinesWithSpace, "")
        }

        $CodeBuildYml = Get-GitHubRepoFileContent -GitHubOrganisation $GitHubOrganisation -RepositoryName $Repo.name -FilePath "pipeline-templates/job/code-build.yml"

        $UpdateCodeBuildYml = $false
        if ($CodeBuildYml) {
            if ($CodeBuildYml.Content -match $DependencyCheckLineInCodeBuildWithSpace) {
                $CodeBuildYml.Content = $CodeBuildYml.Content -replace $DependencyCheckLineInCodeBuildWithSpace, ""
                $UpdateCodeBuildYml = $true
            }   
        }

        $NewBranchName = $NewBranchName.TrimEnd('-')
        $PullRequestTitle = $PullRequestTitle.TrimEnd(' and ')

        if ($UpdatePipelineYml) {

            $PullRequests = Get-GitHubRepoPullRequest -GitHubOrganisation $GitHubOrganisation -RepositoryName $Repo.name
            $PipelineDependenciesPullRequests = $PullRequests | Where-Object { $_.head.ref -like "pipeline-dependencies/*" }

            $ExistingUpToDatePipelineDependenciesPullRequest = $PipelineDependenciesPullRequests | Where-Object { $_.head.ref -eq $NewBranchName }
            if ($ExistingUpToDatePipelineDependenciesPullRequest) {
                $PullRequestUrls += $ExistingUpToDatePipelineDependenciesPullRequest.html_url
            }
            $OutdatedPipelineDependenciesPullRequests = $PipelineDependenciesPullRequests | Where-Object { $_.head.ref -ne $NewBranchName }
            foreach ($OutdatedPipelineDependenciesPullRequest in $OutdatedPipelineDependenciesPullRequests) {
                Write-Warning "Deleting branch $($OutdatedPipelineDependenciesPullRequest.head.ref) and closing its out-dated pull request no. $($OutdatedPipelineDependenciesPullRequest.number) "
                $null = Remove-GitHubRepoBranch -GitHubOrganisation $GitHubOrganisation -RepositoryName $Repo.name -BranchName $OutdatedPipelineDependenciesPullRequest.head.ref -DryRun:$false
            }

            if ($NewBranchName -notin $PipelineDependenciesPullRequests.head.ref -or !$PipelineDependenciesPullRequests) {
                $DefaultBranchRef = Get-GitHubRepoBranchRef -GitHubOrganisation $GitHubOrganisation -RepositoryName $Repo.name -BranchName $Repo.defaultBranchRef.name
                $null = New-GitHubRepoBranch -GitHubOrganisation $GitHubOrganisation -RepositoryName $Repo.name -BaseRefSha $DefaultBranchRef.object.sha -NewBranchName $NewBranchName

                $FileContentParams = @{
                    GitHubOrganisation = $GitHubOrganisation
                    RepositoryName     = $Repo.Name
                    BranchName         = $NewBranchName
                    FilePath           = "azure-pipelines.yml"
                    FileContent        = $PipelineYml.Content
                    CommitMessage      = $PullRequestTitle
                    BaseRefSha         = $PipelineYml.Sha
                }
                $null = Set-GitHubRepoFileContent @FileContentParams

                if ($UpdateCodeBuildYml) {
                    $FileContentParams = @{
                        GitHubOrganisation = $GitHubOrganisation
                        RepositoryName     = $Repo.Name
                        BranchName         = $NewBranchName
                        FilePath           = "pipeline-templates/job/code-build.yml"
                        FileContent        = $CodeBuildYml.Content
                        CommitMessage      = "Removing dependency-check template task"
                        BaseRefSha         = $CodeBuildYml.Sha
                    }
                    $null = Set-GitHubRepoFileContent @FileContentParams
                }

                <#
                $PullRequestParams = @{
                    GitHubOrganisation = $GitHubOrganisation
                    RepositoryName     = $Repo.Name
                    OriginBranchName   = $NewBranchName
                    TargetBranchName   = $Repo.defaultBranchRef.name
                    Title              = $PullRequestTitle
                }
                $PullRequest = New-GitHubRepoPullRequest @PullRequestParams
                Write-Warning "Created PR $($PullRequest.html_url)"
                $PullRequestUrls += $PullRequest.html_url
                #>
            }
        }
    }
    Write-Warning "Pull requests:"
    $PullRequestUrls
}
