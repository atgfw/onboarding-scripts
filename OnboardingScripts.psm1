try {
    Import-Module ActiveDirectory -ErrorAction Stop
}
catch {
    Write-Error "Required module ActiveDirectory could not be imported: $($_.Exception.Message)"
    throw
}

Get-ChildItem -Path $PSScriptRoot\src\*.ps1 | ForEach-Object {
    . $_.FullName
    Export-ModuleMember -Function ([System.IO.Path]::GetFileNameWithoutExtension($_.Name))
}