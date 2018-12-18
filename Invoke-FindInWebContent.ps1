. "$PSScriptRoot\Get-FirstRegexGroupValue.ps1"
function Global:Invoke-FindInWebContent {
    param(
        [System.Xml.XmlElement]$AppXmlInfo,
        [switch]$ReturnUri
    )
    begin {
        if ([Net.ServicePointManager]::SecurityProtocol -ne [Net.SecurityProtocolType]::Tls12) {
            Write-LogEntry -Component $MyInvocation.MyCommand -FileName $Global:LogFileName -Severity 1 -Value "Activating TLS 1.2"
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        }
    }
    process {
        $CurrentUri = $AppXmlInfo.Uri
        $AppXmlInfo.Patterns.Pattern | ForEach-Object { 
            #Write-LogEntry -Component $MyInvocation.MyCommand -FileName $Global:LogFileName -Severity 1 -Value "Find '$([System.Net.WebUtility]::UrlDecode($_))' in data fetched from '$CurrentUri'"
            #Invoke-FindInWebContent -Uri $CurrentUri -Pattern ([System.Net.WebUtility]::UrlDecode($_))
            #Write-Information $CurrentUri
            try {
                $Request = Invoke-WebRequest -SessionVariable VCSessionVariable -ErrorAction Stop -Uri $CurrentUri -UseBasicParsing
            } catch {
                try {
                    #Write-LogEntry -Component $MyInvocation.MyCommand -FileName $Global:LogFileName -Severity 1 -Value "Switching to TLS 1.1 and trying again"
                    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls11
                    $Request = Invoke-WebRequest -SessionVariable VCSessionVariable -ErrorAction Stop -Uri $CurrentUri -UseBasicParsing
                } catch {
                    Write-LogEntry -Component $MyInvocation.MyCommand -FileName $Global:LogFileName -Severity 3 "Error: $_"
                }
                if (-not $Request) {
                    Write-LogEntry -Component $MyInvocation.MyCommand -FileName $Global:LogFileName -Severity 3 -Value "Failed request: $_"
                }
            }
            #Write-Information $Request.Content
            if ($Request.StatusCode -eq 200) {
                #Write-LogEntry -Component $MyInvocation.MyCommand -FileName $Global:LogFileName -Severity 1 -Value  "Request for '$($CurrentUri)' was successful"
                #Write-LogEntry -Component $MyInvocation.MyCommand -FileName $Global:LogFileName -Severity 1 -Value $Request.Content
                $MatchedContent = $Request.Content | Get-FirstRegexGroupValue -Pattern ([System.Net.WebUtility]::UrlDecode($_))
                if (-not [string]::IsNullOrEmpty($MatchedContent)) {
                    #Write-LogEntry -Component $MyInvocation.MyCommand -FileName $Global:LogFileName -Severity 1 -Value "Debug:'$MatchedContent'"
                    if ($ReturnUri.IsPresent -eq $true -and $MatchedContent -notmatch '^http') {
                        #Write-LogEntry -Component $MyInvocation.MyCommand -FileName $Global:LogFileName -Severity 1 -Value "$CurrentUri - $MatchedContent"
                        $CurrentUri = "$($Request.BaseResponse.ResponseUri.AbsoluteUri.SubString(0,($Request.BaseResponse.ResponseUri.AbsoluteUri.LastIndexOf('/')+1)))$MatchedContent"
                        #return
                    }
                    else {
                        Write-Output $MatchedContent
                    }
                }
                #else {
                #    Write-LogEntry -Component $MyInvocation.MyCommand -FileName $Global:LogFileName -Severity 1 -Value "Debug: $($Request.Content)"
                #}
            }
            else {
                Write-LogEntry -Component $MyInvocation.MyCommand -FileName $Global:LogFileName -Severity 3 -Value "Request for '$($CurrentUri)' failed with status $($Request.StatusCode)"
            }
        }
    }
}