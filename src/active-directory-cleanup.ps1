<#
    NOTES/WARNING:
    This is an import of an AD cleanup script that used to be shared through sharepoint.
    I have heard stories of it not working great in the past, so I am working to improve it
    slowly.

    - Noah
#>

import-module activedirectory  
######################### SET INACTIVE DAYS HERE #############################
$DaysInactive = 60
##############################################################################
$domain = "$env:userdnsdomain"  
$time = (Get-Date).Adddays(-($DaysInactive)) 
$Filter = {LastLogonTimeStamp -lt $time -and enabled -eq $true 
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

# 1/10/2025: Added explicit Out-Host to prevent confirmation dialogue from appearing before list of users
Get-ADUser -Filter $Filter -Properties LastLogonTimeStamp | select-object Name,Userprincipalname,Enabled,@{Name="Stamp"; Expression={[DateTime]::FromFileTime($_.lastLogonTimestamp).ToString('yyyy-MM-dd_hh:mm:ss')}} | sort-object stamp | Out-Host

# Output Name and lastLogonTimestamp into CSV  
# select-object Name,@{Name="Stamp"; Expression={[DateTime]::FromFileTime($_.lastLogonTimestamp).ToString('yyyy-MM-dd_hh:mm:ss')}} | # export-csv OLD_User.csv -notypeinformation

$confirmation = Read-Host "Are you Sure You Want To Disable these users? (y/n)"
if ($confirmation -eq 'y') {
    # Disable those users
    Get-ADUser -Filter $Filter -Properties LastLogonTimeStamp | Disable-ADAccount -Confirm

    ## Move those Disabled Users to an OU
    # $DomainDN = get-addomain | select-object DistinguishedName | foreach DistinguishedName
    # New-ADOrganizationalUnit -Name "Disabled Users" -Path $DomainDN
    # $OUPath = "OU=Disabled Users,$DomainDN"
    # Get-ADUser -LDAPFilter "(&(objectCategory=user)(objectClass=user)(useraccountcontrol:1.2.840.113556.1.4.803:=2))" | Move-ADObject -TargetPath $OUPath

} else {
    Write-Host "No users were disabled."
}

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

