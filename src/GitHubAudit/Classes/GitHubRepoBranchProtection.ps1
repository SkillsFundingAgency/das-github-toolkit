class GitHubRepoBranchProtection {
    [String]$BranchName
    [String]$NormalisedBranchName
    [bool]$StrictStatusChecks
    [bool]$StatusChecks
    [bool]$ApprovingReviews
    [int]$RequiredApprovingReviewCount
}
