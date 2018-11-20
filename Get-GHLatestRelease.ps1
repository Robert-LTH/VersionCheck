function Global:Get-GHLatestRelease {
    param(
        [string]$Owner,
        [string]$Repository,
        [string]$Filter,
        [switch]$DownloadUri
    )
    $Headers = @{
        # https://developer.github.com/v3/#user-agent-required
        'user-agent' = 'This should be your emailaddress'
        # https://developer.github.com/v3/#timezones
        'Time-Zone' = 'Enter timezone here'
    }
    $BaseUri = 'https://api.github.com'
    $Uri = Invoke-RestMethod -ErrorAction Stop -Method GET -UseBasicParsing -Uri "$BaseUri/repos/$Owner/$Repository/releases/latest" -Headers $Headers | Select-Object -ErrorAction SilentlyContinue -ExpandProperty assets | Where-Object { $_.name -match $Filter } | Select-Object -ExpandProperty browser_download_url
    if ($DownloadUri.IsPresent) {
        $Uri    
    }
    else {
        $Uri | Get-FirstRegexGroupValue -Pattern '([0-9\.]{2,})'
    }
    
}