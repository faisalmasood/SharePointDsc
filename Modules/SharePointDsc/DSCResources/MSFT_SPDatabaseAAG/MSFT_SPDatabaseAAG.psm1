function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  
        [System.String] 
        $DatabaseName,

        [parameter(Mandatory = $true)]  
        [System.String] 
        $AGName,

        [parameter(Mandatory = $false)] 
        [System.String] 
        $FileShare,

        [parameter(Mandatory = $false)] 
        [ValidateSet("Present","Absent")] 
        [System.String] 
        $Ensure = "Present",

        [parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Getting AAG configuration for $DatabaseName"

    # Check if the April 2014 CU has been installed. The cmdlets have been added in this CU
    if ((Get-SPDSCInstalledProductVersion).FileMajorPart -eq 15 `
        -and (Get-SPDSCInstalledProductVersion).FileBuildPart -lt 4605)
    {
        throw [Exception] ("Adding databases to SQL Always-On Availability Groups " + `
                           "require the SharePoint 2013 April 2014 CU to be installed. " + `
                           "http://support.microsoft.com/kb/2880551")
    }

    if ($Ensure -eq "Present") 
    {
        Write-Verbose -Message "Database(s) must be included in AAG $AGName"
        $result = Invoke-SPDSCCommand -Credential $InstallAccount `
                                      -Arguments ($PSBoundParameters) `
                                      -ScriptBlock {
            $params = $args[0]

            $Ensure = "Present"
            $databases = Get-SPDatabase | Where-Object -FilterScript { 
                $_.Name -like $params.DatabaseName 
            }

            if ($null -ne $databases) 
            {
                foreach ($database in $databases)
                {
                    $ag = $database.AvailabilityGroup
                    if ($null -ne $ag) 
                    {
                        if ($ag.Name -ne $params.AGName) 
                        {
                            $Ensure = "Absent"
                        }
                    }
                    else
                    {
                        $Ensure = "Absent"
                    }
                }
            }
            else
            {
                Write-Verbose -Message "Specified database(s) not found."
                $Ensure = ""
            }

            return @{
                DatabaseName = $params.DatabaseName
                AGName = $params.AGName
                FileShare = $params.FileShare
                Ensure = $Ensure
                InstallAccount = $params.InstallAccount
            }
        } 
    }
    else 
    {
        Write-Verbose -Message "Database(s) must not be included in an AAG $AGName"
        $result = Invoke-SPDSCCommand -Credential $InstallAccount `
                                    -Arguments $PSBoundParameters `
                                    -ScriptBlock {
            $params = $args[0]
            
            $databases = Get-SPDatabase | Where-Object -FilterScript { 
                $_.Name -like $params.DatabaseName
            }

            $Ensure = "Absent"
            if ($null -ne $databases) 
            {
                foreach ($database in $databases)
                {
                    $ag = $database.AvailabilityGroup
                    if ($null -ne $ag) 
                    {
                        $Ensure = "Present"
                    }
                }
            }
            else
            {
                Write-Verbose -Message "Specified database(s) not found."
                $Ensure = ""
            }

            return @{
                DatabaseName = $params.DatabaseName
                AGName = $params.AGName
                FileShare = $params.FileShare
                Ensure = $Ensure
                InstallAccount = $params.InstallAccount
            }
        }
    }
    return $result
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]  
        [System.String] 
        $DatabaseName,

        [parameter(Mandatory = $true)]  
        [System.String] 
        $AGName,

        [parameter(Mandatory = $false)] 
        [System.String] 
        $FileShare,

        [parameter(Mandatory = $false)] 
        [ValidateSet("Present","Absent")] 
        [System.String] 
        $Ensure = "Present",

        [parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Setting AAG configuration for $DatabaseName"

    # Check if the April 2014 CU has been installed. The cmdlets have been added in this CU
    if ((Get-SPDSCInstalledProductVersion).FileMajorPart -eq 15 `
        -and (Get-SPDSCInstalledProductVersion).FileBuildPart -lt 4605)
    {
        throw [Exception] ("Adding databases to SQL Always-On Availability Groups " + `
                           "require the SharePoint 2013 April 2014 CU to be installed. " + `
                           "http://support.microsoft.com/kb/2880551")
    }

    if ($Ensure -eq "Present") 
    {
        Write-Verbose -Message "Checking AAG settings for $DatabaseName"
        Invoke-SPDSCCommand -Credential $InstallAccount `
                            -Arguments ($PSBoundParameters) `
                            -ScriptBlock {
            $params = $args[0]

            $databases = Get-SPDatabase | Where-Object -FilterScript { 
                $_.Name -like $params.DatabaseName
            }

            if ($null -ne $databases) 
            {
                foreach ($database in $databases)
                {
                    $ag = $database.AvailabilityGroup
                    if ($null -ne $ag) 
                    {
                        if ($ag.Name -ne $params.AGName) 
                        {
                            # Remove it from the current AAG first
                            Remove-DatabaseFromAvailabilityGroup -AGName $params.AGName `
                                                                 -DatabaseName $database.Name `
                                                                 -Force

                            # Now add it to the AAG it's meant to be in
                            $addParams = @{
                                AGName = $params.AGName
                                DatabaseName = $database.Name
                            }
                            if ($params.ContainsKey("FileShare")) 
                            {
                                $addParams.Add("FileShare", $params.FileShare)
                            }
                            Add-DatabaseToAvailabilityGroup @addParams
                        }
                    }
                    else
                    {
                        Write-Verbose -Message "Adding $DatabaseName to $AGName"
                        $cmdParams = @{
                            AGName = $params.AGName
                            DatabaseName = $database.Name
                        }
                        if ($params.ContainsKey("FileShare")) 
                        {
                            $cmdParams.Add("FileShare", $params.FileShare)
                        }
                        Add-DatabaseToAvailabilityGroup @cmdParams
                    }
                }
            }
            else
            {
                throw "Specified database(s) not found."
            }
        }
    } 
    else 
    {
        Write-Verbose -Message "Removing $DatabaseName from $AGName"
        Invoke-SPDSCCommand -Credential $InstallAccount `
                            -Arguments $PSBoundParameters `
                            -ScriptBlock {
            $params = $args[0]

            $databases = Get-SPDatabase | Where-Object -FilterScript { 
                $_.Name -like $params.DatabaseName
            }

            if ($null -ne $databases)
            {
                foreach ($database in $databases)
                {
                    Remove-DatabaseFromAvailabilityGroup -AGName $params.AGName `
                                                         -DatabaseName $database.Name `
                                                         -Force
                }
            }
            else
            {
                throw "Specified database(s) not found."
            }
        }
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]  
        [System.String] 
        $DatabaseName,

        [parameter(Mandatory = $true)]  
        [System.String] 
        $AGName,

        [parameter(Mandatory = $false)] 
        [System.String] 
        $FileShare,

        [parameter(Mandatory = $false)] 
        [ValidateSet("Present","Absent")] 
        [System.String] 
        $Ensure = "Present",

        [parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Testing AAG configuration for $DatabaseName"

    $PSBoundParameters.Ensure = $Ensure

    $CurrentValues = Get-TargetResource @PSBoundParameters
    
    return Test-SPDscParameterState -CurrentValues $CurrentValues `
                                    -DesiredValues $PSBoundParameters `
                                    -ValuesToCheck @("Ensure")
}

