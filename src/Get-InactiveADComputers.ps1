function Get-InactiveADComputers() {
    <#
        .SYNOPSIS
        Gets all users who haven't logged in recently.

        .DESCRIPTION
        Gets all AD users who either has a LastLogon value in the past $DaysInactive or who has LastLogonTimestamp
        value in the past ($DaysInactive + 14 days).

        Filters out names that are -like any string in $IgnoreList

        .OUTPUTS
        Microsoft.ActiveDirectory.Management.ADUser. Returns one or more user objects.

    #>
    param (
    <#
        .PARAMETER DaysInactive
        Number of days of inactivity required for a user to be declared Inactive
    #>
        [int]$DaysInactive = 60,
    <# 
        .PARAMETER IgnoreList
        List of strings to be compared against the Name of each computer with -like and filtered out
    #>
        [string[]]$IgnoreList = @(),
        [string]$SearchBase = $null
    )

    $localThreshold = (Get-Date).AddDays(-$DaysInactive)
    $replicatedThreshold = (Get-Date).AddDays(-($DaysInactive+14)) # LastLogonTimestamp synchronization delay

    $usernameFilter = {
        $usernameFilterOutput = $true
        foreach ($ignoreItem in $IgnoreList) {
            $usernameFilterOutput = ($_ -notlike $ignoreItem) -and $usernameFilterOutput
        }
        $usernameFilterOutput
    }

    $filter = {
        [DateTime]::FromFileTime($_.LastLogon) -lt $localThreshold -and
        [DateTime]::FromFileTime($_.LastLogonTimeStamp) -lt $replicatedThreshold -and
        $_.enabled -eq $true 
    }

    $params = @{
        Filter = '*'
        Properties = 'LastLogon', 'LastLogonTimeStamp'
    }

    if ($SearchBase) {
        $params['SearchBase'] = $SearchBase
    }

    return Get-ADComputer @params |
        Where-Object $filter | Where-Object $usernameFilter
}