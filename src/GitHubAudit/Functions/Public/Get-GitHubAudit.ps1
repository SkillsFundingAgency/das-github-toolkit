<#
.SYNOPSIS
A PowerShell function for auditing GitHub configuration

.DESCRIPTION
A PowerShell function for auditing GitHub configuration.  Utilises the GitHub REST API (v3) and GraphQL API (v4)

.PARAMETER PatToken
(optional) A PatToken can be passed directly to this cmdlet but it is preferable to use Set-GitHubSessionInformation
A PAT token with the following permissions:
notifications, public_repo, read:discussion, read:enterprise, read:org, read:packages, read:public_key, read:repo_hook, read:user, repo:invite, repo:status, repo_deployment, user:email

To audit private repo config using the V3 REST API you will need 'repo', ie full control permissions over repos.  This is required to retrieve Team permissions for repositories.

.PARAMETER PathToConfigFile
(optional)  Path to a configuration file that defines the baseline configuration for a repo and the repositories to be audited.
Defaults to the config file contained in the module: GitHubToolKit/GitHubAudit/config.json

.PARAMETER StorageAccountName
(optional) The storage account to save the audit output to.  The output will be saved into a container called github-audit-results.  The container will be created if it doesn't exist.

.PARAMETER StorageAccountKey
(optional) The account access key for the storage account.  The account access key is required to enable the cmdlet to create the container.

.EXAMPLE
Gets the repositories with incorrect Licence files and outputs a list of their names along with the current Licence file
$Audit = Get-GitHubAudit -PatToken <not-a-real-token>
$Audit | Where-Object { $_.Licence.CorrectConfiguration -eq $false } | Format-Table -Property RepositoryName, @{Name="Licence"; Expression={$_.Licence.ActualValue}}

.EXAMPLE
Gets the repositories with incorrect branch protection and outputs a list of their names along with some Branch Protection Rule properties
$Audit = Get-GitHubAudit -PatToken <not-a-real-token>
$Audit | Where-Object { $_.BranchProtection.CorrectConfiguration -eq $false } | Format-Table RepositoryName, @{Name="BranchName"; Expression={$_.BranchProtection.ActualValue.BranchName}}, @{Name="StrictStatusChecks"; Expression={$_.BranchProtection.ActualValue.StrictStatusChecks}}, @{Name="RequiredApprovingReviewCount"; Expression={$_.BranchProtection.ActualValue.RequiredApprovingReviewCount}}
#>
function Get-GitHubAudit {
    [CmdletBinding(DefaultParametersetName='None')][OutputType('System.Management.Automation.PSObject')]
    param(
        [Parameter(Mandatory=$false)]
        [string]$PatToken,
        [Parameter(Mandatory=$false)]
        [string]$PathToConfigFile = "$PSScriptRoot/../../../GitHubAudit/config.json",
        [Parameter(Mandatory=$true, ParameterSetName = "BlobOutput")]
        [string]$StorageAccountName,
        [Parameter(Mandatory=$true, ParameterSetName = "BlobOutput")]
        [string]$StorageAccountKey
    )

    $SessionInfo = Get-GitHubSessionInformation
    if (!$SessionInfo) {
        if ($PatToken) {
            Set-GitHubSessionInformation -PatToken $PatToken
        }
        else {
            Write-Error "No PatToken supplied and GitHubSessionInformation is not set, exiting function."
            throw
        }
    }

    $Config = Get-Content -Path $PathToConfigFile -Raw | ConvertFrom-Json

    $Audit = @()

    Write-Verbose "Getting repos ..."
    $Repos = Get-GitHubRepo -GitHubOrg $Config.managedRepos.organisation
    foreach ($Repo in $Repos) {
        $Audit += New-Object -TypeName GitHubRepoAudit -Property @{ RepositoryName = $Repo.name; IsArchived = $Repo.isArchived; IsPrivateRepository = $Repo.isPrivate }
    }

    Write-Verbose "Starting Access Control Audit audit ..."
    $Audit = Get-GitHubTeamsAndPermissionsAudit -AuditResults $Audit -Config $Config

    Write-Verbose "Starting Branch Protection audit ..."
    $Audit = Get-GitHubBranchProtectionRulesAudit -AuditResults $Audit -Config $Config

    Write-Verbose "Starting Licence audit ..."
    $Audit = Get-GitHubLicencesAudit -AuditResults $Audit -Config $Config

    [array]$ResultsToReturn = $Audit
    Write-Verbose "Removing excluded repos"
    $ResultsToReturn = $ResultsToReturn | Where-Object { $_.RepositoryName -notmatch $Config.managedRepos.excludedPattern }
    $ResultsToReturn = $ResultsToReturn | Where-Object { $_.RepositoryName -notin $Config.managedRepos.excludedRepos }
    if (!$Config.managedRepos.includeArchivedRepos) {
        Write-Verbose "Excluding archived repositories"
        $ResultsToReturn = $ResultsToReturn | Where-Object { $_.IsArchived -eq $false }
    }
    if (!$Config.managedRepos.includePrivateRepos) {
        Write-Verbose "Excluding private repositories"
        $ResultsToReturn = $ResultsToReturn | Where-Object { $_.IsPrivateRepository -eq $false }
    }

    Write-Verbose "Selecting included repos"
    # Strip out any results with RepositoryName's that don't match the includedPattern
    $ResultsToReturn = $ResultsToReturn | Where-Object { $_.RepositoryName -match $Config.managedRepos.includedPattern }
    # Add any explicitly included repos back in from the original Audit results object
    $ResultsToReturn += $Audit | Where-Object { $_.RepositoryName -in $Config.managedRepos.includedRepos }

    Write-Verbose "Checking configuration results"
    foreach ($Repository in $Audit) {
        $PropertyConfigValidityStates = @()
        $AuditedProperties = $Repository | Get-Member | Where-Object { $_.Definition.Split(" ")[0] -eq "GitHubAuditResult" }
        foreach ($AuditedProperty in $AuditedProperties) {
            try {
                $CorrectConfiguration = (Select-Object -InputObject $Repository -ExpandProperty $AuditedProperty.Name).CorrectConfiguration
                $PropertyConfigValidityStates += $null -eq $CorrectConfiguration ? $false : $CorrectConfiguration
            }
            catch [Exception]{
                Write-Error "Error retrieving PropertyConfigValidityState for $($AuditedProperty.Name) on $($Repository.RepositoryName)"
                $PropertyConfigValidityStates += $false
            }

        }
        $Repository.CorrectConfiguration = $PropertyConfigValidityStates -contains $false -or $PropertyConfigValidityStates.Count -ne $AuditedProperties.Count ? $false : $true
    }

    Write-Verbose "Audit complete."

    if ($PSCmdlet.ParameterSetName -eq "BlobOutput") {
        $ContainerName = "github-audit-results"
        $StorageContext = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey
        $StorageContainer = Get-AzStorageContainer -Name $ContainerName -Context $StorageContext -ErrorAction SilentlyContinue
        if (!$StorageContainer) {
            Write-Verbose "Creating container $ContainerName in storage account $StorageAccountName"
            New-AzStorageContainer -Name $ContainerName -Context $StorageContext
        }
        $OutputFileName = "GitHubAuditResults_$([DateTime]::Now.ToString("yyyyMMdd-HHmm")).json"
        $OutputFile = New-Item -Name $OutputFileName -ItemType File
        Set-Content -Path $OutputFile.FullName -Value $($ResultsToReturn | ConvertTo-Json -Depth 5)
        Write-Verbose "Uploading audit results to blob $($OutputFileName) in container $ContainerName of storage account $StorageAccountName"
        Set-AzStorageBlobContent -File $OutputFile.FullName -Container $ContainerName -Blob $OutputFileName -Context $StorageContext
        $OutputFile | Remove-Item
    }

    $ResultsToReturn
}
