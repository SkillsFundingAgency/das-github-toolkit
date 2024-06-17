function Invoke-GitHubRestMethod {
    <#
    .SYNOPSIS
    A module specific wrapper for Invoke-ResetMethod

    .DESCRIPTION
    A module specific wrapper for Invoke-ResetMethod

    .PARAMETER Method
    METHOD: GET, POST, PUT, DELETE, PATCH

    .PARAMETER URI
    Service URI

    .PARAMETER Body
    Payload for the request, if applicable

    .PARAMETER InFile
    The File to upload

    .PARAMETER OutFile
    Path to downloaded file

    .PARAMETER ContentType
    The content type of the file to upload

    .PARAMETER Headers
    Optional Headers to send. This will override the default set provided

    .PARAMETER CollectionName
    Optional.  The name of the collection returned by the GitHub REST API, by default will look for a collection called "items".

    .INPUTS
    System.String

    .OUTPUTS
    System.Management.Automation.PSObject

    .EXAMPLE
    Invoke-GitHubRestMethod -Method POST -URI /api/release/1

    #>
    [CmdletBinding(DefaultParameterSetName="Standard")][OutputType('System.Management.Automation.PSObject')]
    Param (
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateSet("HEAD","GET","POST","PUT","DELETE", "PATCH")]
        [String]$Method,

        [Parameter(Mandatory=$true, Position=1)]
        [ValidateNotNullOrEmpty()]
        [String]$URI,

        [Parameter(Mandatory=$false, Position=2, ParameterSetName="WithBody")]
        [ValidateNotNullOrEmpty()]
        [String]$Body,

        [Parameter(Mandatory=$false, Position=3, ParameterSetName="InFile")]
        [ValidateNotNullOrEmpty()]
        [String]$InFile,

        [Parameter(Mandatory=$false, Position=4, ParameterSetName="InFile")]
        [ValidateNotNullOrEmpty()]
        [String]$ContentType,

        [Parameter(Mandatory=$false, Position=5, ParameterSetName="OutFile")]
        [ValidateNotNullOrEmpty()]
        [String]$OutFile,

        [Parameter(Mandatory=$false, Position=6)]
        [ValidateNotNullOrEmpty()]
        [System.Collections.IDictionary]$Headers,

        [Parameter(Mandatory=$false, Position=7)]
        [ValidateNotNullOrEmpty()]
        [String]$CollectionName
    )

    function Wait-GitHubRateLimit {
        param(
            [string]$Api,
            [int]$Limit,
            [int]$Remaining,
            [int]$Reset
        )

        $RateLimitRemainingPercentage = $Remaining / $Limit
        Write-Verbose "$Api rate limit remaining percentage: $($RateLimitRemainingPercentage * 100)"
        if ($RateLimitRemainingPercentage -lt 0.20) {
            $TimeToRateLimitReset = ((Get-Date -UnixTimeSeconds $Reset) - (Get-Date)).TotalSeconds
            if ($TimeToRateLimitReset -gt 0) {
                Write-Warning "Approaching Rate Limit, waiting for $TimeToRateLimitReset seconds"
                Start-Sleep -Seconds $TimeToRateLimitReset
            }
        }
    }

    # --- Build full URI
    $BaseURI = "https://api.github.com"
    $FullURI = "$($BaseUri)$($URI)"
    Write-Verbose "Full URI: $FullURI"

    # --- Grab the sessionstate variable & test throw if it is null
    $SessionInfo = Get-GitHubSessionInformation -Verbose:$VerbosePreference
    if (!$SessionInfo) {
        Write-Error "Session information is null or empty."
        return
    }

    # --- If the headers parameter is not passed use the default
    if ($PSBoundParameters.ContainsKey("Headers")) {
        foreach ($SessionHeaderKey in $SessionInfo.Headers.Keys) {
            if (!$Headers[$SessionHeaderKey]) {
                $Headers[$SessionHeaderKey] = $SessionInfo.Headers[$SessionHeaderKey]
            }
        }
    }
    else {
        $Headers = $SessionInfo.Headers
    }

    # Ensure Content-Type is present if Body is provided
    if ($PSBoundParameters.ContainsKey("Body") -and !$Headers.ContainsKey("Content-Type")) {
        $Headers["Content-Type"] = "application/json"
    }

    $Params = @{
        Method = $Method
        Headers = $Headers
        Uri = $FullURI
        RetryIntervalSec = 15
        MaximumRetryCount = 3
    }

    if ($PSBoundParameters.ContainsKey("Body")) {
        $Params.Add("Body", $Body)
    }

    if ($PSBoundParameters.ContainsKey("OutFile")) {
        $Params.Add("OutFile", $OutFile)
    }

    if ($PSBoundParameters.ContainsKey("InFile")) {
        $UploadURI = "https://uploads.github.com"
        $Params.Uri = "$($UploadURI)$($URI)"
        $Params.Add("InFile", $InFile)
        $Params.Add("ContentType", $ContentType)
    }

    Write-Verbose "Parameters: $Params"

    try {
        $Response = Invoke-RestMethod @Params -ResponseHeadersVariable ResponseHeaders -Verbose:$VerbosePreference
    }
    catch {
        Write-Error "Error in Invoke-RestMethod: $_"
        $Response = $_.ErrorDetails.Message
    }

    # check for rate limiting
    if ($ResponseHeaders) {
        $WaitParams = @{
            Api = $ResponseHeaders["X-RateLimit-Resource"][0]
            Limit = ([int]$ResponseHeaders["X-RateLimit-Limit"][0])
            Remaining = ([int]$ResponseHeaders["X-RateLimit-Remaining"][0])
            Reset = ([int]$ResponseHeaders["X-RateLimit-Reset"][0])
        }
        Wait-GitHubRateLimit @WaitParams
    }
    else {
        Write-Error "No response headers"
        Write-Warning "Response: $Response"
    }

    # check for pagination
    if ($null -ne $ResponseHeaders.Link) {
        Write-Verbose "Response contains multiple pages"
        $PageNumbers = Select-String "page=(\d*)" -InputObject $ResponseHeaders.Link -AllMatches | ForEach-Object {$_.matches}
        $LastPage = $PageNumbers[-1].Groups[1].Value
        for ($i = 2; $i -le $LastPage; $i++) {
            Start-Sleep -Seconds 2
            $PageLink = $ResponseHeaders.Link.Split(";")[0] -replace "(page=)(\d*)","page=$i"
            $PageLink = $PageLink.Replace("<","").Replace(">","")
            $Params["Uri"] = $PageLink
            try {
                $PageResponse = Invoke-RestMethod @Params
            }
            catch [Exception] {
                Write-Error $_.Exception.Message
                throw
            }

            if ($PageResponse.GetType().ToString() -eq "System.Object[]") {
                $Response += $PageResponse
            }
            elseif ($CollectionName) {
                if ((($Response | Get-member -Name $CollectionName).Definition -split " ")[0] -eq "Object[]") {
                    Remove-Variable AppendedCollection -ErrorAction SilentlyContinue
                    $AppendedCollection = $Response | Select-Object -ExpandProperty $CollectionName
                    $AppendedCollection += $PageResponse | Select-Object -ExpandProperty $CollectionName
                    $Response | Add-Member -Name $CollectionName -Value $AppendedCollection -MemberType NoteProperty -Force
                }
                else {
                    Write-Error "$CollectionName is not a collection"
                }
            }
            elseif ($PageResponse.items -and $PageResponse.items.GetType().ToString() -eq "System.Object[]") {
                $Response.items += $PageResponse.items
            }
            else {
                Write-Warning "Collection not found in page response"
            }

            if ($ResponseHeaders) {
                $WaitParams = @{
                    Api = $ResponseHeaders["X-RateLimit-Resource"][0]
                    Limit = ([int]$ResponseHeaders["X-RateLimit-Limit"][0])
                    Remaining = ([int]$ResponseHeaders["X-RateLimit-Remaining"][0])
                    Reset = ([int]$ResponseHeaders["X-RateLimit-Reset"][0])
                }
                Wait-GitHubRateLimit @WaitParams
            }
            else {
                Write-Error "No response headers, waiting 60 seconds"
                Start-Sleep -Seconds 60
            }
        }
    }

    Write-Output $Response
}
