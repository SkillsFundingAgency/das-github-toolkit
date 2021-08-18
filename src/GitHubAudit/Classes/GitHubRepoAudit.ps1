class GitHubRepoAudit {
    [String]$RepositoryName
    [bool]$CorrectConfiguration
    [bool]$IsArchived
    [bool]$IsPrivateRepository
    [GitHubAuditResult]$BranchProtection
    [GitHubAuditResult]$AccessControlList
    [GitHubAuditResult]$Licence
}
