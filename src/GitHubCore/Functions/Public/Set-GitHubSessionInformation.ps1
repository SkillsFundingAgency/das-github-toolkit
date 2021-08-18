function Set-GitHubSessionInformation {
<#
    .SYNOPSIS
    Create information for this session

    .DESCRIPTION
    Create information for this session

    .PARAMETER Username
    The username that has priveleges to manage the repository

    .PARAMETER APIKey
    The personal access token associated with the username

    .PARAMETER PatToken
    A personal access token

    .INPUTS
    System.String

    .OUTPUTS
    System.Management.Automation.PSObject

    .EXAMPLE
    Set-GitHubSessionInformation -Username user -APIKey xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="Low")][OutputType('System.Management.Automation.PSObject')]

    Param (

        [Parameter(Mandatory=$true, ParameterSetName="ApiKey")]
        [ValidateNotNullOrEmpty()]
        [String]$Username,

        [Parameter(Mandatory=$true, ParameterSetName="ApiKey")]
        [ValidateNotNullOrEmpty()]
        [String]$APIKey,

        [Parameter(Mandatory=$true, ParameterSetName="PatToken")]
        [ValidateNotNullOrEmpty()]
        [String]$PatToken

    )

    Write-Verbose -Message "Creating new SessionState variable GithubSessionInformation"

    try {

        if ($PSCmdlet.ParameterSetName -eq "ApiKey") {

            if ($PSCmdlet.ShouldProcess("GithubSessionInformation")){

                $EncodedAuth = [System.Text.Encoding]::UTF8.GetBytes("$($Username):$($APIKey)")
    
                $Script:GithubSessionInformation = [PSCustomObject]@{
    
                    Username = $Username
                    Authorization = [System.Convert]::ToBase64String($EncodedAuth)
                    Headers = @{
                        "Accept" = "application/vnd.github.v3+json"
                        "Authorization" = "Basic [System.Convert]::ToBase64String($EncodedAuth)"
                    }
    
                }
    
            }

        }
        elseif ($PSCmdlet.ParameterSetName -eq "PatToken") {
            $Script:GithubSessionInformation = [PSCustomObject]@{
    
                Headers = @{
                    "Accept" = "application/vnd.github.v3+json"
                    "Authorization" = "Bearer $PatToken"
                }

            }
        }


    } catch {

        throw $_.Exception

    }

}