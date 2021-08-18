function Invoke-GitHubRestMethod {
<#
    .SYNOPSIS
    A module specific wrapper for Invoke-ResetMethod

    .DESCRIPTION
    A module specific wrapper for Invoke-ResetMethod

    .PARAMETER Method
    METHOD: GET, POST, PUT, DELETE

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
        [System.Collections.IDictionary]$Headers

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
        if ($RateLimitRemainingPercentage -lt 0.25) {
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

    # --- Grab the sessionstate variable & test throw if it is null
    $SessionInfo = Get-GitHubSessionInformation -Verbose:$VerbosePreference

    # --- If the headers parameter is not passed use the deafult
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

    $Params = @{

        Method = $Method
        Headers = $Headers
        Uri = $FullURI

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

    try {

        $Response = Invoke-RestMethod @Params -ResponseHeadersVariable ResponseHeaders -Verbose:$VerbosePreference
    
    }
    catch {

        $Response = $_.ErrorDetails.Message
    
    }
    
    # check for rate limiting
    if ($ResponseHeaders) {
        $WaitParams =@{
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
        #use regex to retrieve the page properties from the Link response header
        $PageNumbers = Select-String "page=(\d*)" -InputObject $ResponseHeaders.Link -AllMatches | ForEach-Object  {$_.matches}
        #get the value of the last page
        $LastPage = $PageNumbers[1].Groups[1].Value
        for ($i = 2; $i -le $LastPage; $i++) {

            #pause to ensure rate limit not hit
            Start-Sleep -Seconds 3
            #replace the page parameter value with $i
            $PageLink = $ResponseHeaders.Link.Split(";")[0] -replace "(page=)(\d*)","page=$i"
            #strip out the angle brackets from the url
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
            elseif ($PageResponse.items.GetType().ToString() -eq "System.Object[]") {
                $Response.items += $PageResponse.items
            }

            if ($ResponseHeaders) {
                $WaitParams =@{
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