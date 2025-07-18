<#
.SYNOPSIS
    Retrieves logon events for a specified Active Directory user from the past week.

.DESCRIPTION
    This script prompts for a username and retrieves logon events (EventID 4624) from the Security log
    for the specified user within the past week. It resolves IP addresses to computer names, displays
    a progress bar during processing, and groups the events by computer name, selecting only the most
    recent logon event for each computer.

.EXAMPLE
    PS C:\> .\Get-LogonEvents.ps1
    Enter the username: johndoe

    This command retrieves logon events for the user 'johndoe' from the past week.
#>

$username = Read-Host -Prompt "Enter the username"

$Query = @"
<QueryList>
  <Query Id='0' Path='Security'>
    <Select Path='Security'>*[System[(EventID=4624) and TimeCreated[timediff(@SystemTime) &lt;= 604800000]]] and *[EventData[Data[@Name='TargetUserName'] and (Data='$username')]]</Select>
  </Query>
</QueryList>
"@

$events = Get-WinEvent -FilterXml $Query
$totalEvents = $events.Count
$progress = 0
$previousComputers = @{}

$events | ForEach-Object {
    $progress++
    Write-Progress -Activity "Processing Events" -Status "$progress of $totalEvents" -PercentComplete (($progress / $totalEvents) * 100)

    $username = $_.Properties[5].Value
    $ipAddress = $_.Properties[18].Value
    $computerName = ([System.Net.Dns]::GetHostEntry($ipAddress)).HostName

    if (-not $previousComputers.ContainsKey($computerName)) {
        $previousComputers[$computerName] = $true
        [PSCustomObject]@{
            TimeGenerated = $_.TimeCreated
            User          = $username
            Computer      = $computerName
        }
    }
} | Group-Object Computer | ForEach-Object { $_.Group | Select-Object -First 1 }