function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $NameIdentifier,

        [Parameter()]
        [System.Boolean]
        $UseSessionCookies = $false,

        [Parameter()]
        [System.Boolean]
        $AllowOAuthOverHttp = $false,

        [Parameter()]
        [System.Boolean]
        $AllowMetadataOverHttp = $false,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount,

        [Parameter()]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present"
    )

    Write-Verbose -Message "Getting Security Token Service Configuration"

    $result = Invoke-SPDSCCommand -Credential $InstallAccount `
                                  -Arguments $PSBoundParameters `
                                  -ScriptBlock {
        $params = $args[0]

        $config = Get-SPSecurityTokenServiceConfig
        $nullReturn = @{
            Name = $params.Name
            NameIdentifier = $params.NameIdentifier
            UseSessionCookies = $params.UseSessionCookies
            AllowOAuthOverHttp = $params.AllowOAuthOverHttp
            AllowMetadataOverHttp = $params.AllowMetadataOverHttp
            Ensure = "Absent"
            InstallAccount = $params.InstallAccount
        }
        if ($null -eq $config)
        {
            return $nullReturn
        }

        return @{
            Name = $config.Name
            NameIdentifier = $config.NameIdentifier
            UseSessionCookies = $config.UseSessionCookies
            AllowOAuthOverHttp = $config.AllowOAuthOverHttp
            AllowMetadataOverHttp = $config.AllowMetadataOverHttp
            Ensure = "Present"
            InstallAccount = $params.InstallAccount
        }
    }
    return $result
}

function Set-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $NameIdentifier,

        [Parameter()]
        [System.Boolean]
        $UseSessionCookies = $false,

        [Parameter()]
        [System.Boolean]
        $AllowOAuthOverHttp = $false,

        [Parameter()]
        [System.Boolean]
        $AllowMetadataOverHttp = $false,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount,

        [Parameter()]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present"
    )

    Write-Verbose -Message "Setting Security Token Service Configuration"

    if($Ensure -eq "Absent")
    {
        throw "This ressource cannot undo Security Token Service Configuration changes. `
        Please set Ensure to Present or ommit the resource"
    }

    Invoke-SPDSCCommand -Credential $InstallAccount `
                        -Arguments $PSBoundParameters `
                        -ScriptBlock {
        $config = Get-SPSecurityTokenServiceConfig
        $config.Name = $params.Name
        $config.NameIdentifier = $params.NameIdentifier
        $config.UseSessionCookies = $params.UseSessionCookies
        $config.AllowOAuthOverHttp = $params.AllowOAuthOverHttp
        $config.AllowMetadataOverHttp = $params.AllowMetadataOverHttp

        $config.Update()
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $NameIdentifier,

        [Parameter()]
        [System.Boolean]
        $UseSessionCookies = $false,

        [Parameter()]
        [System.Boolean]
        $AllowOAuthOverHttp = $false,

        [Parameter()]
        [System.Boolean]
        $AllowMetadataOverHttp = $false,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount,

        [Parameter()]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present"
    )

    Write-Verbose -Message "Testing the Security Token Service Configuration"

    $PSBoundParameters.Ensure = $Ensure

    $CurrentValues = Get-TargetResource @PSBoundParameters

    return Test-SPDscParameterState -CurrentValues $CurrentValues `
                                    -DesiredValues $PSBoundParameters `
                                    -ValuesToCheck @("Ensure")
}

Export-ModuleMember -Function *-TargetResource
