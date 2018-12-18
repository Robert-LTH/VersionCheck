function Global:Invoke-PreparePSADT {
    param(
        [string]$Destination,
        [string]$PSADTSource
    )
    try {
        Get-Item -Path $PSADTSource -ErrorAction Stop | Out-Null
        Get-Item -Path "$PSADTSource\Deploy-Application.ps1" -ErrorAction Stop | Out-Null
    } catch {
        throw $_
    }
    if (-not (Test-Path -Path $Destination -ErrorAction SilentlyContinue)) {
        Write-LogEntry -Component $MyInvocation.MyCommand -FileName $Global:LogFileName -Severity 1 -Value "Creating folder '$UnknownVersionFolder')"
        $Folder = New-Item -Path $Destination -ItemType Container
    }
    else {
        $Folder = $true
    }
    if ($Folder) {
        Copy-Item -Path "$PSADTSource\*" -Destination $Destination -Recurse -Exclude 'Thumbs.db'
    }
}