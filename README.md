# cleanup-script

This is a collection of scripts to AD cleanup/onboarding scripts

# Installation and Use

```powershell
Remove-Item "$env:TEMP\OnboardingScripts" -Recurse
Remove-Item "$env:TEMP\OnboardingScripts.zip" 
Remove-Item "$($env:ProgramFiles)\WindowsPowerShell\Modules\OnboardingScripts" -Recurse

Invoke-WebRequest `
    -Uri https://github.com/atgfw/onboarding-scripts/archive/refs/heads/main.zip `
    -OutFile "$env:TEMP\OnboardingScripts.zip"

Expand-Archive `
    -Path "$env:TEMP\OnboardingScripts.zip" `
    -DestinationPath "$env:TEMP\OnboardingScripts"

Get-ChildItem -Path "$env:TEMP\OnboardingScripts" `
    | Select-Object -First 1 `
    | Move-Item -Destination "$($env:ProgramFiles)\WindowsPowerShell\Modules\OnboardingScripts"

Import-Module OnboardingScripts
```

# Exposed Functions

## ADCleanupCLI

Interactive CLi tool to disable inactive AD Users and Computers and move them to a specified OU

## Get-InactiveADUsers

Custom cmdlet to get a list of inactive AD Users

## Get-InactiveADComputers

Custom cmdlet to get a list of inactive AD Computers
