. "$PSScriptRoot\Get-FirstRegexGroupValue.ps1"
function Global:Invoke-FindInWebContent {
    param(
        [System.Xml.XmlElement]$AppXmlInfo,
        $Uri,
        $Patterns,
        [switch]$ReturnUri
    )
    begin {
        if ([Net.ServicePointManager]::SecurityProtocol -ne [Net.SecurityProtocolType]::Tls12) {
            Write-LogEntry -Component $MyInvocation.MyCommand -FileName $Global:LogFileName -Severity 1 -Value "Activating TLS 1.2"
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        }
    }
    process {
        if ($AppXmlInfo) {
            $CurrentUri = $AppXmlInfo.Uri
            $_Patterns = $AppXmlInfo.Patterns.Pattern
        }
        else {
            $CurrentUri = $Uri
            $_Patterns = $Patterns
        }
        $_Patterns | ForEach-Object -begin { $i = 1 } {
            #Write-Debug $_
            #Write-LogEntry -Component $MyInvocation.MyCommand -FileName $Global:LogFileName -Severity 1 -Value "Find '$([System.Net.WebUtility]::UrlDecode($_))' in data fetched from '$CurrentUri'"
            #Invoke-FindInWebContent -Uri $CurrentUri -Pattern ([System.Net.WebUtility]::UrlDecode($_))
            #Write-Information $CurrentUri
            try {
                Write-Debug $CurrentUri
                $Request = Invoke-WebRequest -SessionVariable VCSessionVariable -ErrorAction Stop -Uri $CurrentUri -UseBasicParsing
            } catch {
                try {
                    Write-LogEntry -Component $MyInvocation.MyCommand -FileName $Global:LogFileName -Severity 1 -Value "Switching to TLS 1.1 and trying again"
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
                $MatchedContent = ([string]::new($Request.Content)) | Get-FirstRegexGroupValue -Pattern ([System.Net.WebUtility]::UrlDecode($_))
                Write-Debug "$MatchedContent"
                if (-not [string]::IsNullOrEmpty($MatchedContent)) {
                    #Write-LogEntry -Component $MyInvocation.MyCommand -FileName $Global:LogFileName -Severity 1 -Value "Debug:'$MatchedContent'"
                    if ($ReturnUri.IsPresent -eq $true -and $MatchedContent -notmatch '^http') {
                        $BaseUri = "$($Request.BaseResponse.RequestMessage.RequestUri.Scheme)://$($Request.BaseResponse.RequestMessage.RequestUri.Host)"
                        #if ($Request.BaseResponse.RequestMessage.RequestUri.PathAndQuery -notcontains $MatchedContent) {
                        #    $BaseUri += $Request.BaseResponse.RequestMessage.RequestUri.AbsolutePath
                        #}
                        if (-not (Split-Path -Path $MatchedContent -Parent)) {
                            Write-LogEntry -Component $MyInvocation.MyCommand -FileName $Global:LogFileName -Severity 1 -Value "ABSOLUTEPATH $($BaseUri + $Request.BaseResponse.RequestMessage.RequestUri.AbsolutePath)"
                            $BaseUri += $Request.BaseResponse.RequestMessage.RequestUri.AbsolutePath
                        }
                        if ($MatchedContent.SubString(0,1) -ne '/' -and ($BaseUri.LastIndexOf('/')+1) -ne $BaseUri.Length) {
                            Write-LogEntry -Component $MyInvocation.MyCommand -FileName $Global:LogFileName -Severity 1 -Value "No SLASH $($BaseUri + $MatchedContent)"
                            $CurrentUri = "$($BaseUri)/$MatchedContent"
                        }
                        else {
                            if ($MatchedContent.SubString(0,2) -eq '//') {
                                Write-LogEntry -Component $MyInvocation.MyCommand -FileName $Global:LogFileName -Severity 1 -Value "CurrentURI: $CurrentURI"
                                $CurrentUri = $MatchedContent -replace '//',"$($Request.BaseResponse.RequestMessage.RequestUri.Scheme)://"
                                Write-LogEntry -Component $MyInvocation.MyCommand -FileName $Global:LogFileName -Severity 1 -Value "CurrentURI: $CurrentURI"
                            }
                            else {
                                Write-LogEntry -Component $MyInvocation.MyCommand -FileName $Global:LogFileName -Severity 1 -Value "CurrentUri = $BaseUri $MatchedContent"
                                $CurrentUri = "$($BaseUri)$MatchedContent"
                            }
                        }
                        #Write-LogEntry -EntryType CMLogEntry -Component $MyInvocation.MyCommand -FileName $Global:LogFileName -Severity 3 -Value "$i / $($_Patterns.Count)"
                        if ($i -eq ($_Patterns.Count)) {
                            $return = ($CurrentUri -replace '[^https:]\/\/','/')
                            Write-LogEntry -Component $MyInvocation.MyCommand -FileName $Global:LogFileName -Severity 1 -Value "No more patterns, will return $return"
                            return $return
                        }
                    }
                    else {
                        if ($i -eq ($_Patterns.Count)) {
                            return $MatchedContent
                        }
                        else {
                            $CurrentUri = $MatchedContent
                        }
                    }
                }
                else {
                    Write-LogEntry -Component $MyInvocation.MyCommand -FileName $Global:LogFileName -Severity 1 -Value "Debug: $($Request.Content)"
                }
            }
            else {
                Write-LogEntry -Component $MyInvocation.MyCommand -FileName $Global:LogFileName -Severity 3 -Value "Request for '$($CurrentUri)' failed with status $($Request.StatusCode)"
            }
            $i++
        }
    }
}