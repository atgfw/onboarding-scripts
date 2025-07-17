
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
        Write-Host 'WARNING: This script normally requires "Run as Administrator"' -ForegroundColor "Red"
        if ((Read-Host -Prompt "Continue without elevation? (y/n)") -notlike "y") {
            break
        }
        Write-Host "Running Without Elevation" -ForegroundColor "Red"
    }

    Write-Host "== Step 1: Disable Inactive Users ==" -ForegroundColor "Green"
    $users = Get-InactiveADUsers
    Write-Host "Inactive Users to Disable:" -ForegroundColor "Green"
    $users |
        Format-Table Name, SamAccountName,
        @{ Name='LastLogon (Sync)'; Expression={ Convert-ADFileTime $_.lastLogonTimestamp } },
        @{ Name='LastLogon (Local DC)'; Expression={ Convert-ADFileTime $_.LastLogon } }
    if ((Read-Host -Prompt "Disable These Users? (y/n)") -notlike "y") {
        Write-Host "Cancelling Operation" -ForegroundColor "Red"
        break
    }
    $disabledUsers = $users | Disable-AdAccount -Confirm -PassThru
    if ($disabledUsers.count -eq 0) {
        Write-Host "No Users Were Disabled" -ForegroundColor "Red"
        break
    }
    Write-Host "The Following Users Were Disabled:" -ForegroundColor "Green"
    $disabledUsers |
        Format-Table Name, DistinguishedName, ObjectGUID
    
    Write-Host "== Step 2: Move Disabled Users to a new Disabled Users OU ==" -ForegroundColor "Green"
    $selectedOU = OUMenu
    Write-Host "OU Selected: $($selectedOU.DistinguishedName)" -ForegroundColor "Yellow"
    if ((Read-Host -Prompt "Move newly-disabled users to this OU? (y/n)") -notlike 'y') {
        Write-Host "Cancelling Operation" -ForegroundColor "Red"
        break
    }
    $movedUsers = $disabledUsers | Move-ADObject -TargetPath ($selectedOU.DistinguishedName) -PassThru
    Write-Host "The Following Users Were Moved:" -ForegroundColor "Green"
    $movedUsers |
        Format-Table Name, DistinguishedName, ObjectGUID
    
    Write-Host "== Step 3: Disable Inactive Computers ==" -ForegroundColor "Green"
    $computers = Get-InactiveADComputers
    Write-Host "Inactie Computers to Disable:" -ForegroundColor "Green"
    $computers |
        Format-Table Name,
        @{ Name='LastLogon (Sync)'; Expression={ Convert-ADFileTime $_.lastLogonTimestamp } },
        @{ Name='LastLogon (Local DC)'; Expression={ Convert-ADFileTime $_.LastLogon } }
    if ((Read-Host -Prompt "Disable These Computers? (y/n)") -notlike "y") {
        Write-Host "Cancelling Operation" -ForegroundColor "Red"
        break
    }
    $disabledComputers = $computers | Disable-AdAccount -Confirm -PassThru
    if ($disabledComputers.count -eq 0) {
        Write-Host "No Computers were disabled" -ForegroundColor "Red"
        break
    }
    Write-Host "The Following Computers Were Disabled:" -ForegroundColor "Green"
    $disabledComputers |
        Format-Table Name, DistinguishedName, ObjectGUID
    
    Write-Host "== Step 4: Move Disabled Computers to a Disabled Computers OU ==" -ForegroundColor "Green"
    $selectedOU = OUMenu
    Write-Host "OU Selected: $($selectedOU.DistinguishedName)" -ForegroundColor "Yellow"
    if ((Read-Host -Prompt "Move newly-disabled computers to this OU? (y/n)") -notlike 'y') {
        Write-Host "Cancelling Operation" -ForegroundColor "Red"
        break
    }
    $movedComputers = $disabledComputers | Move-ADObject -TargetPath ($selectedOU.DistinguishedName) -PassThru
    Write-Host "The Following Computers Were Moved:" -ForegroundColor "Green"
    $movedComputers |
        Format-Table Name, DistinguishedName, ObjectGUID
}

<#
 CLI-Based OU Selection/Creation Menu
 -> ADOrganizationalUnit
#>
function OUMenu {
    $selectedOU = $null
    while (-not $selectedOU) {
        Write-Host "Select an option:" -ForegroundColor "Yellow"
        Write-Host "(1): Create a new OU" -ForegroundColor "Yellow"
        Write-Host "(2): Enter the DistinguishedName of an existing OU" -ForegroundColor "Yellow"
        Write-Host "(3): Select an existing OU from a GUI menu" -ForegroundColor "Yellow"
        $userInput = Read-Host
        switch ($userInput) {
            1 {
                $ouName = Read-Host "Enter a name for the new OU"
                $selectedOU = New-ADOrganizationalUnit -Name $ouName -PassThru
                if ($selectedOU) {
                    Write-Host "OU Created Successfully! ($($selectedOU.DistinguishedName))" `
                        -ForegroundColor "Green"
                }
            }
            2 {
                $ouDistinguishedName = Read-Host "Enter the DistinguishedName of the target OU"
                $selectedOU = Get-ADOrganizationalUnit -Identity $ouDistinguishedName
            }
            3 {
                $selectedOU = Get-ADOrganizationalUnit -Identity (Select-OU)
            }
            default {Write-Host "No match"}
        }
    }
    return $selectedOU
}

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