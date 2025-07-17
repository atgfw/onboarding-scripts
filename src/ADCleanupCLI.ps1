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
    # Returns $true if running elevated, otherwise $false
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
        ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        Write-Host 'This script normally requires "Run as Administrator"' -ForegroundColor "Red"
        if ((Read-Host -Prompt "Continue without elevation? (y/n)") -notlike "y") {
            break
        }
        Write-Host "Running without elevation" -ForegroundColor "Red"
    }

    Write-Host "Step 1: Disable Inactive Users" -ForegroundColor "Green"
    $users = Get-InactiveADUsers
    Write-Host "Inactive Users to Disable:" -ForegroundColor "Green"
    $users |
        Format-Table Name, SamAccountName,
        @{ Name='LastLogon (Sync)'; Expression={ Convert-ADFileTime $_.lastLogonTimestamp } },
        @{ Name='LastLogon (Local DC)'; Expression={ Convert-ADFileTime $_.LastLogon } }
    if ((Read-Host -Prompt "Disable These Users? (y/n)") -notlike "y") {
        Write-Host "Cancelling operation" -ForegroundColor "Red"
        break
    }
    $disabledUsers = $users | Disable-AdAccount -Confirm -PassThru
    if ($disabledUsers.count -eq 0) {
        Write-Host "No Users were disabled" -ForegroundColor "Red"
        break
    }
    Write-Host "The Following Users Were Disabled:" -ForegroundColor "Green"
    $disabledUsers |
        Format-Table Name, DistinguishedName, ObjectGUID
    
    Write-Host "Step 2: Move Disabled Users to a new Disabled Users OU" -ForegroundColor "Green"
    $selectedOU = $null
    while (-not $selectedOU) {
        Write-Host "Select an option:" -ForegroundColor "Yellow"
        Write-Host "(1): Create a new disabled users OU" -ForegroundColor "Yellow"
        Write-Host "(2): Enter the DistinguishedName of an existing disabled users OU" -ForegroundColor "Yellow"
        Write-Host "(3): Select an existing OU from a GUI menu" -ForegroundColor "Yellow"
        Write-Host "(exit): Exit this menu" -ForegroundColor "Yellow"
        $userInput = Read-Host
        if ($userInput -like "*exit*") {
            break
        }
        switch ($userInput) {
            1 {
                $ouName = Read-Host "Enter a name for the new Disabled Users OU"
                $selectedOU = New-ADOrganizationalUnit -Name $ouName -PassThru
                if ($selectedOU) {
                    Write-Host "OU Created ($($selectedOU.DistinguishedName))!" -ForegroundColor "Green"
                }
            }
            2 {
                $ouDistinguishedName = Read-Host "Enter the DistinguishedName of the target OU"
                $selectedOU = Get-ADOrganizationalUnit -Identity $ouDistinguishedName
            }
            3 {
                $selectedOU = Get-ADOrganizationalUnit -Identity Select-OU
            }
            default {Write-Host "No match"}
        }
    }
    Write-Host "OU Selected: $($selectedOU.DistinguishedName)" -ForegroundColor "Green"
    if (Read-Host -Prompt "Move newly-disabled users to this OU? (y/n)" -notlike 'y') {
        Write-Host "Cancelling operation" -ForegroundColor "Red"
        break
    }
    $movedUsers = $disabledUsers | Move-ADObject -TargetPath ($selectedOU.DistinguishedName) -PassThru
    Write-Host "Moved Users:"
    $movedUsers |
        Format-Table Name, DistinguishedName, ObjectGUID
}