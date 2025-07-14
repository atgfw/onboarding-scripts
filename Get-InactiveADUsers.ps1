Import-Module ActiveDirectory

function Get-InactiveADUsers() {
    param (
        [int]$DaysInactive = 60,
        [string[]]$IgnoreList = @(
            '*scan*', '*vpn*', '*service*', '*QB*', '*sync*',
            '*aad*', '*rely*', '*MSOL*', '*sql*', '*copier*',
            '*$*', '*ldap*', '*titan*', '*sense*'
        ),
        [string]$SearchBase = $null
    )

    $time = (Get-Date).AddDays(-$DaysInactive)

    $filter = {
        [DateTime]::FromFileTime($_.LastLogonTimeStamp) -lt $time -and
        $_.enabled -eq $true -and
        ($IgnoreList -notcontains $null -and
            ($IgnoreList | ForEach-Object { $_pattern = $_; $_.userprincipalname -notlike $_pattern }) -notcontains $false)
    }

    $params = @{
        Filter = '*'
    }

    if ($SearchBase) {
        $params['SearchBase'] = $SearchBase
    }

    return Get-ADUser @params |
        Where-Object $filter
}