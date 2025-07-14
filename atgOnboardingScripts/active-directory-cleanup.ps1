<#
    Active Directory Cleanup Utilities
#>

import-module activedirectory  

function Get-InactiveADUsers() {
    param (
        [int]$DaysInactive = 60
    )
    $time = (Get-Date).Adddays(-($DaysInactive)) 
    $filter = {LastLogonTimeStamp -lt $time -and enabled -eq $true 
        -and userprincipalname -notlike '*scan*' 
        -and userprincipalname -notlike '*vpn*' 
        -and userprincipalname -notlike '*service*' 
        -and userprincipalname -notlike '*QB*' 
        -and userprincipalname -notlike '*sync*' 
        -and userprincipalname -notlike '*aad*'   
        -and userprincipalname -notlike '*rely*'
        -and userprincipalname -notlike '*MSOL*'
        -and userprincipalname -notlike '*sql*'
        -and userprincipalname -notlike '*copier*'
        -and userprincipalname -notlike '*$*'
        -and userprincipalname -notlike '*ldap*'
        -and userprincipalname -notlike '*titan*'
        -and userprincipalname -notlike '*sense*'}

    return Get-ADUser -Filter $Filter
}

<# Disables all inactive Users #>
function Disable-InactiveADUsers() {
    param (
        [int]$DaysInactive = 60,
        [ADOrgan]
        [switch]$WhatIf
    )

    # Respect WhatIf preference to the best of our ability
    if ($WhatIf) {
        $WhatIfPreference = $true
    }

    # Get and show Inactive Users
    $inactiveUsers = Get-InactiveADUsers -DaysInactive $DaysInactive
    $inactiveUsers `
        | Select-Object Name,Userprincipalname,Enabled,@{Name="Stamp"; Expression={[DateTime]::FromFileTime($_.lastLogonTimestamp).ToString('yyyy-MM-dd_hh:mm:ss')}} `
        | sort-object stamp `
        | Out-Host

    # Ask for confirmation before disabling
    $confirmation = Read-Host "Are you Sure You Want To Disable these users? (y/n)"
    if ($confirmation -eq 'y') {
        foreach ($inactiveUser in $inactiveUsers) {
            # Disable those users
            Disable-ADAccount $inactiveUser
            # Move those Disabled Users to an OU
            # TODO: Find solution for selecting disabled users OU
            # Move-ADObject $OU.DistinguishedName
        }
    } else {
        Write-Host "No users were disabled."
    }
}

# Output Name and lastLogonTimestamp into CSV  
# select-object Name,@{Name="Stamp"; Expression={[DateTime]::FromFileTime($_.lastLogonTimestamp).ToString('yyyy-MM-dd_hh:mm:ss')}} | # export-csv OLD_User.csv -notypeinformation
function Disable-InactiveADComputers {
    ## Disable inactive computers, to be better integrated later

    #Custom property for Last Logon in table
    $hash_lastLogonTimestamp = @{Name="LastLogonTimeStamp";Expression={([datetime]::FromFileTime($_.LastLogonTimeStamp))}}

    # Get all AD Computer with lastLogonTimestamp less than our time and set to enable 
    Get-ADComputer -Filter {LastLogonTimeStamp -lt $time -and enabled -eq $true} -ResultPageSize 2000 -resultSetSize $null -Properties lastLogonTimestamp,Name,OperatingSystem,SamAccountName,DistinguishedName `
        | Select-Object samaccountname,$hash_lastLogonTimestamp,OperatingSystem,SID `
        | Sort-object samaccountname

    # Disable those computers
    Get-ADComputer -Filter {LastLogonTimeStamp -lt $time -and enabled -eq $true} -Properties lastLogonTimestamp,Name,OperatingSystem,SamAccountName,DistinguishedName `
        | Disable-ADAccount

    # Move those Disabled Computers to an OU
    $DomainDN = get-addomain `
        | select-object DistinguishedName `
        | Foreach-Object DistinguishedName
    New-ADOrganizationalUnit -Name "Disabled Computers" -Path $DomainDN
    $OUPath = "OU=Disabled Computers,$DomainDN"
    Get-ADComputer -LDAPFilter "(&(objectCategory=computer)(objectClass=computer)(useraccountcontrol:1.2.840.113556.1.4.803:=2))" | Move-ADObject -TargetPath $OUPath
}

<# Creates a disabled Users OU and returns it #>
function New-DisabledUsersOU {
    param (
        [switch]$WhatIf
    )
    if ($WhatIf) {
        $WhatIfPreference = $true
    }

    # Create Disabled Users OU
    $ouParams = @{
        Name = "Disabled Users"
        Path = (Get-ADDomain).DistinguishedName
    }
    $OU = New-ADOrganizationalUnit @ouParams
    return $OU
}