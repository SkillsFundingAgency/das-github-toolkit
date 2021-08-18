param(
    [Parameter(Mandatory = $true)]
    [string]$Base64AuthInfo,
    [Parameter(Mandatory = $true)]
    [string]$OrgName
)

$BaseUrl = "https://api.github.com"

$Repos = [System.Collections.ArrayList]::new()
$Uri = "$BaseUrl/orgs/$OrgName/repos"
$NextPage = 1

do {
    $Parameters = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)
    $Parameters['page'] = $NextPage
    $Parameters['type'] = "public"
    $Parameters['per_page'] = "100"
    $Request = [System.UriBuilder]$Uri
    $Request.Query = $Parameters.ToString()

    $RepoRequest = Invoke-WebRequest -Uri $Request.Uri -Headers @{ Authorization = "Basic $Base64AuthInfo" }

    $Repos.AddRange(($RepoRequest.Content | ConvertFrom-Json -Depth 99))

    if (!$RepoRequest.RelationLink.last) {
        break
    }
    [int]$NextPage = [System.Web.HttpUtility]::ParseQueryString(([System.Uri]$RepoRequest.RelationLink.next).Query)['page']
    [int]$LastPage = [System.Web.HttpUtility]::ParseQueryString(([System.Uri]$RepoRequest.RelationLink.last).Query)['page']

} while ($NextPage -le $LastPage)

Write-Output $Repos
