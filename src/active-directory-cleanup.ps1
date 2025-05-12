<#
    TO RUN:
#>

import-module activedirectory  

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

<# Disables all inactive Users #>
function Disable-DisactiveADUsers() {
    param (
        [int]$DaysInactive = 60,
        [switch]$WhatIf
    )
    if ($WhatIf) {
        $WhatIfPreference = $true
    }

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

    $inactiveUsers = Get-ADUser -Filter $Filter -Properties LastLogonTimeStamp
    $inactiveUsers 
        | Select-Object Name,Userprincipalname,Enabled,@{Name="Stamp"; Expression={[DateTime]::FromFileTime($_.lastLogonTimestamp).ToString('yyyy-MM-dd_hh:mm:ss')}}
        | sort-object stamp
        | Out-Host
    $confirmation = Read-Host "Are you Sure You Want To Disable these users? (y/n)"
    if ($confirmation -eq 'y') {
        foreach ($inactiveUser in $inactiveUsers) {
            # Disable those users
            Disable-ADAccount $inactiveUser
            # Move those Disabled Users to an OU
            Move-ADObject $OU.DistinguishedName
        }
    } else {
        Write-Host "No users were disabled."
    }
}


# Output Name and lastLogonTimestamp into CSV  
# select-object Name,@{Name="Stamp"; Expression={[DateTime]::FromFileTime($_.lastLogonTimestamp).ToString('yyyy-MM-dd_hh:mm:ss')}} | # export-csv OLD_User.csv -notypeinformation


<#
## Disable inactive computers, to be better integrated later

$hash_lastLogonTimestamp = @{Name="LastLogonTimeStamp";Expression={([datetime]::FromFileTime($_.LastLogonTimeStamp))}}
$hash_pwdLastSet = @{Name="pwdLastSet";Expression={([datetime]::FromFileTime($_.pwdLastSet))}}

# Get all AD Computer with lastLogonTimestamp less than our time and set to enable 
Get-ADComputer -Filter {LastLogonTimeStamp -lt $time -and enabled -eq $true} -ResultPageSize 2000 -resultSetSize $null -Properties lastLogonTimestamp,Name,OperatingSystem,SamAccountName,DistinguishedName | select samaccountname,$hash_lastLogonTimestamp,OperatingSystem,SID | Sort-object samaccountname

# Disable those computers
Get-ADComputer -Filter {LastLogonTimeStamp -lt $time -and enabled -eq $true} -Properties lastLogonTimestamp,Name,OperatingSystem,SamAccountName,DistinguishedName | Disable-ADAccount

# Move those Disabled Computers to an OU
$DomainDN = get-addomain | select-object DistinguishedName | foreach DistinguishedName
New-ADOrganizationalUnit -Name "Disabled Computers" -Path $DomainDN
$OUPath = "OU=Disabled Computers,$DomainDN"
Get-ADComputer -LDAPFilter "(&(objectCategory=computer)(objectClass=computer)(useraccountcontrol:1.2.840.113556.1.4.803:=2))" | Move-ADObject -TargetPath $OUPath
#>