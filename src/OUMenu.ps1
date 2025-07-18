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