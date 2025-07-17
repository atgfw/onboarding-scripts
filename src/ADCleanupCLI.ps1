# [DateTime]::FromFileTime wrapper that handles blank entries
function Convert-ADFileTime {
    param(
        [Parameter(Mandatory=$true)]
        [long]$FileTime
    )
    if ($FileTime -and $FileTime -ne 0) {
        return [DateTime]::FromFileTime($FileTime)
    } else {
        return $null   # or 'Never'
    }
}

<#
    Lists inactive Users,
    Prompts disable for each user,
    Lists newly disabled users,
    Prompts to create/find disabled users OU,
    Moves disabled users to new OU
#>
function ADCleanupCLI {
    $users = Get-InactiveADUsers
    Write-Host "Inactive Users to Disable:"
    $users |
        Format-Table Name, SamAccountName,
        @{ Name='LastLogon (Sync)'; Expression={ Convert-ADFileTime $_.lastLogonTimestamp } },
        @{ Name='LastLogon (Local DC)'; Expression={ Convert-ADFileTime $_.LastLogon } }
    if (Read-Host -Prompt "Disable These Users? (y/n)" -notlike "y") {
        Write-Host "Cancelling operation"
        break
    }
    $disabledUsers = $users | Disable-AdAccount -Confirm -PassThru
    Write-Host "The Following Users Were Disabled"
    $disabledUsers |
        Format-Table
}