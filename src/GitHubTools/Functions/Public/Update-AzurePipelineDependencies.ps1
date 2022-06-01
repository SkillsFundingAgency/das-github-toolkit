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
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Justification = "Script creates a GitHub branch which is a non-destructive change.")]
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
        | Where-Object { ($_.type -eq "github")`
                -and ($_.name -eq "SkillsFundingAgency/das-platform-building-blocks" -or $_.name -eq "SkillsFundingAgency/das-platform-automation") }
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

        $NewBranchName = $NewBranchName.TrimEnd('-')
        $PullRequestTitle = $PullRequestTitle.TrimEnd(' and ')

        if ($UpdatePipelineYml) {

            $PullRequests = Get-GitHubRepoPullRequest -GitHubOrganisation $GitHubOrganisation -RepositoryName $Repo.name
            $PipelineDependenciesPullRequests = $PullRequests | Where-Object { $_.head.ref -like "pipeline-dependencies/*" }
            if ($NewBranchName -notin $PipelineDependenciesPullRequests.head.ref -or !$PipelineDependenciesPullRequests) {
                if ($PipelineDependenciesPullRequests) {
                    foreach ($PipelineDependenciesPullRequest in $PipelineDependenciesPullRequests) {
                        Write-Warning "Deleting out-dated pull request $($PipelineDependenciesPullRequest.number) for branch $($PipelineDependenciesPullRequest.head.ref)"
                        Remove-GitHubRepoBranch -GitHubOrganisation $GitHubOrganisation -RepositoryName $Repo.name -BranchName $PipelineDependenciesPullRequest.head.ref
                    }
                }
                $DefaultBranchRef = Get-GitHubRepoBranchRef -GitHubOrganisation $GitHubOrganisation -RepositoryName $Repo.name -BranchName $Repo.defaultBranchRef.name
                New-GitHubRepoBranch -GitHubOrganisation $GitHubOrganisation -RepositoryName $Repo.name -BaseRefSha $DefaultBranchRef.object.sha -NewBranchName $NewBranchName

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
            }
            else {
                foreach ($PipelineDependenciesPullRequest in $PipelineDependenciesPullRequests) {
                    $PullRequestUrls += $PipelineDependenciesPullRequest.html_url
                }
            }
        }
    }
    Write-Host ""
    Write-Warning "Pull requests:"
    $PullRequestUrls
}
