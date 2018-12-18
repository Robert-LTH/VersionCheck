param(
    $VersionUri,
    $VersionPattern,
    $DownloadUri,
    $DownloadPattern,
    $OutFile
)

. ".\Get-FirstRegexGroupValue.ps1"
. ".\Write-LogEntry.ps1"

$Global:LogFileName = "New-VersionCheckConfig.log"

if ([Net.ServicePointManager]::SecurityProtocol -ne [Net.SecurityProtocolType]::Tls12) {
    Write-LogEntry -Component $MyInvocation.MyCommand -FileName $Global:LogFileName -Severity 1 -Value "Activating TLS 1.2"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls11
}
function Get-UriMatch {
    param(
        $Uri,
        $Pattern
    )
    $Request = Invoke-WebRequest -ErrorAction SilentlyContinue -Uri $Uri -UseBasicParsing
    if ($Request.StatusCode -eq 200) {
        Write-LogEntry -Component $MyInvocation.MyCommand -FileName $Global:LogFileName -Severity 1 -Value  "[Get-UriMatch] Request for '$Uri' was successful"
        $Request.Content | Get-FirstRegexGroupValue -Pattern $Pattern
    }
    else {
        Write-Debug $Request.StatusCode
    }
    
}
[xml]$ExampleXML = Get-Content -Path "$PSScriptRoot\example.xml"
 try {
        if ($VersionUri) {
            $VersionMatch = Get-UriMatch -Uri $VersionUri -Pattern $VersionPattern
            if ($VersionMatch) {
                $pattern = $ExampleXML.CreateElement('pattern')
                $pattern.InnerText = [System.Net.WebUtility]::UrlEncode($VersionPattern)
                #$ExampleXML.application.version.unknown.patterns.ReplaceChild($pattern,$ExampleXML.application.version.unknown.patterns.FirstChild)
                $ExampleXML.application.version.unknown.patterns.AppendChild($pattern) | Out-Null
                $ExampleXML.application.version.unknown.uri = $VersionUri
            }
        }
        if ($DownloadUri) {
            $DownloadMatch = Get-UriMatch -Uri $DownloadUri -Pattern $DownloadPattern
            if ($DownloadMatch) {
                $pattern = $ExampleXML.CreateElement('pattern')
                $pattern.InnerText = [System.Net.WebUtility]::UrlEncode($DownloadPattern)
                #$ExampleXML.application.version.unknown.patterns.ReplaceChild($pattern,$ExampleXML.application.version.unknown.patterns.FirstChild)
                $ExampleXML.application.download.patterns.AppendChild($pattern) | Out-Null
                $ExampleXML.application.download.uri = $DownloadUri
            }
        }
    } catch {
        $_
    }

    if ($VersionMatch -or $DownloadMatch) {
        if (-not ($OutFile)) {
            Write-Host "VersionMatch: $VersionMatch"
            Write-Host "DownloadMatch: $DownloadMatch"
        }
        else {
            $ExampleXML.Save($OutFile)
        }
    }