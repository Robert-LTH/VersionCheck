. "$PSScriptRoot\Get-FtpDirList.ps1"
. "$PSScriptRoot\Invoke-FindInWebContent.ps1"
function Global:Get-AppVersion {
    param(
        [System.Xml.XmlElement]$AppXmlInfo,
        $Format,
        $Path
    )
    process {
        if ($Path) {
            #Write-LogEntry -Component $MyInvocation.MyCommand -FileName $Global:LogFileName -Severity 1 -Value "Local path"
            $UnformattedString = Get-ChildItem -Directory -Path $Path | ForEach-Object { Get-FirstRegexGroupValue -Content $_.Name -Pattern $AppXmlInfo.pattern } | Sort-Object | Select-Object -Last 1
        }
        elseif ($AppXmlInfo.Uri -match '^ftp') {
            #Write-LogEntry -Component $MyInvocation.MyCommand -FileName $Global:LogFileName -Severity 1 -Value "FTP path"
            try {
                $UnformattedString = Get-FtpDirList -Uri $AppXmlInfo.Uri | Select-Object -ExpandProperty 'Name' | Select-String -Pattern ($AppXmlInfo.patterns.pattern | Select-Object -Last 1) | Sort-Object |Select-Object -Last 1
            } catch {
                Write-LogEntry -Component $MyInvocation.MyCommand -FileName $Global:LogFileName -Severity 3 -Value "Failed to get directory list from ftp: $_"
                #$UnformattedString = '0.0'
            }
        }
        else {
            #Write-LogEntry -Component $MyInvocation.MyCommand -FileName $Global:LogFileName -Severity 1 -Value "URI"
            $UnformattedString = Invoke-FindInWebContent -AppXmlInfo $AppXmlInfo
        }
        if ([string]::IsNullOrEmpty($UnformattedString)) {
            $UnformattedString = '0.0'
        }
        try {
            if ($Format -and $UnformattedString -ne '0.0') {
                $Parameters = $UnformattedString | Select-String -Pattern ([System.Net.WebUtility]::UrlDecode($Format.Pattern)) | Select-Object -ExpandProperty Matches | ForEach-Object { $_.Groups[1..($_.Groups.Count)] }#| Select-Object -ExpandProperty Value #-Last $($_.Count-1)
                if ($Parameters) {
                    $StringOutput = $Format.string -f $Parameters
                    Write-Debug "$($format.string) -f '$Parameters' = '$StringOutput'"
                } else {
                    Write-LogEntry -Component $MyInvocation.MyCommand -FileName $Global:LogFileName -Severity 3 -Value "Problem while trying for format parameters."
                    $StringOutput = '0.0'
                }
            }
            else {
                $StringOutput = $UnformattedString
            }
            #Write-Debug "$StringOutput"
            if (-not ([string]::IsNullOrEmpty($StringOutput)) -and $StringOutput -notin $AppXmlInfo.ignoreversion) {
                if ($StringOutput -notmatch '\.') {
                    $StringOutput = "{0}.0" -f $StringOutput
                }
                $VersionObject = New-Object -TypeName psobject
                $VersionObject  | Add-Member 'Object' ([System.Version]::new($StringOutput))
                $VersionObject  | Add-Member -NotePropertyName 'String' -NotePropertyValue $StringOutput
                $VersionObject
            }
        } catch {
            Write-LogEntry -Component $MyInvocation.MyCommand -FileName $Global:LogFileName -Severity 3 -Value "Problem while processing '$StringOutput': $_"
        } 
    }
}