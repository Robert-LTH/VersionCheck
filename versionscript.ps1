param(
    [switch]$DoDownload,
    [switch]$SendToTeams,
    [switch]$Debug
)

. "$PSScriptRoot\Get-ScriptSettings.ps1"
. "$PSScriptRoot\Write-LogEntry.ps1"

. "$PSScriptRoot\Get-AppVersion.ps1"

. "$PSScriptRoot\Read-AppInfoXMLFile.ps1"
. "$PSScriptRoot\Invoke-VersionCheck.ps1"
. "$PSScriptRoot\New-VersionCard.ps1"

. "$PSScriptRoot\Invoke-DownloadUnknownVersion.ps1"


$ScriptSettingsRegistryPath = 'Registry::HKEY_LOCAL_MACHINE\Software\VersionCheck'
$ErrorActionPreference = "Stop"
$Global:LogFileName = 'VersionCheck.log'

$TranscriptFile = "$PSScriptRoot\Logs\Transcript.log"
$Global:VersionErrors = @()

Write-Host '#####################################'
Write-Host ''
Write-Host "`t`tVersionCheck!"
Write-Host ''
Write-Host '#####################################'
Write-Host ''


$LogFilePath = Write-LogEntry -ReturnPath -Component $MyInvocation.MyCommand -FileName $Global:LogFileName -Severity 1 -Value "VersionCheck begin"
Write-Host "Logging to '$LogFilePath'"
if ($Debug.IsPresent) {
    Write-LogEntry -Component $MyInvocation.MyCommand -FileName $Global:LogFileName -Severity 1 -Value "DEBUG ACTIVE - Start trancscript to '$TranscriptFile'"
    Start-Transcript -Path $TranscriptFile -Force
}

$Settings = Get-ScriptSettings -RegistryPath $ScriptSettingsRegistryPath

Write-LogEntry -Component $MyInvocation.MyCommand -FileName $Global:LogFileName -Severity 1 -Value "Will traverse '$($Settings.ApplicationShare)'"
try {
    $UnknownVersions = Get-ChildItem -Recurse -Depth 1 -ErrorAction Stop -Path $Settings.ApplicationShare -Filter 'AppInfo.xml' `
                            | Read-AppInfoXMLFile `
                                | Where-Object { $_.XML.application.work.Item('versioncheck') -or $_.XML.application.work.Item('version') } `
                                    | Invoke-VersionCheck `
                                        | Where-Object { $_.KnownVersion.Object -lt $_.UnknownVersion.Object }
} catch {
    Write-LogEntry -Component $MyInvocation.MyCommand -FileName $Global:LogFileName -Severity 3 -Value $_.InvocationInfo.Line
    Write-LogEntry -Component $MyInvocation.MyCommand -FileName $Global:LogFileName -Severity 3 -Value "Error: $_"
    return
}

if ($SendToTeams.IsPresent) {
    $CardVersions = @{
        facts = @(@{name = 'Name';value='Version'})
        activityTitle    = 'List of unknown versions'
        activityImage    = 'http://icons.iconarchive.com/icons/icons8/windows-8/512/Media-Controls-Volume-Up-icon.png' # this value would be a path to a nice image you would like to display in notifications
    }
    $UnknownVersions | Select-Object -Property @{Name='value';Expression={$_.UnknownVersion.String}},@{Name='name';Expression={$_.Name}} | ForEach-Object { $CardVersions.facts += $_ }
    if (($Global:VersionErrors | Measure-Object).Count -gt 0) {
        $VersionProblems = @{
            facts         = @(@{name = ''; value = 'Problem'})
            activityTitle = 'Problems when checking versions'
            #activityImage    = 'http://icons.iconarchive.com/icons/icons8/windows-8/512/Media-Controls-Volume-Up-icon.png' # this value would be a path to a nice image you would like to display in notifications
        }
        $Global:VersionErrors | Select-Object -Property @{Name = 'value'; Expression = {$_}}, @{Name = 'name'; Expression = {''}} | ForEach-Object { $VersionProblems.facts += $_ }
    }
    $Card = New-VersionCard -Versions $CardVersions -SeenErrors $VersionProblems
    try {
        Invoke-RestMethod -ErrorAction Stop -Method POST -Uri $Settings.TeamsWebhookUri -Body $Card | Out-Null
    } catch {
        # Dig into the exception to get the Response details.
        # Note that value__ is not a typo.
        Write-LogEntry -Component $MyInvocation.MyCommand -FileName $Global:LogFileName -Severity 3 -Value "StatusCode: $($_.Exception.Response.StatusCode.value__)"
        Write-LogEntry -Component $MyInvocation.MyCommand -FileName $Global:LogFileName -Severity 3 -Value "StatusDescription: $($_.Exception.Response.StatusDescription)"
    }
}
elseif ($DoDownload.IsPresent) {
    #$UnknownVersions.XML.application.download.format.pattern
    #return
    $UnknownVersions `
        | Where-Object { $_.XML.application.work.Item('download') } `
            | Invoke-DownloadUnknownVersion -Settings $Settings | ForEach-Object -Begin { Write-LogEntry -Component $MyInvocation.MyCommand -FileName $Global:LogFileName -Severity 1 -Value "The following were downloaded:" } {
                Write-LogEntry -Component $MyInvocation.MyCommand -FileName $Global:LogFileName -Severity 1 -Value $_.Name
            }
}
else {
    $UnknownVersions
    Write-Host $Global:VersionErrors
}

if ($Debug.IsPresent) {
    Stop-Transcript
}

Write-LogEntry -Component $MyInvocation.MyCommand -FileName $Global:LogFileName -Severity 1 -Value "VersionCheck end"