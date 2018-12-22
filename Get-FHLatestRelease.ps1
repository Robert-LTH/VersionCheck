. "$PSScriptRoot\Get-FirstRegexGroupValue.ps1"
function Get-FHLatestRelease {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        $SearchTerm,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        $Filter,
        [switch]$DownloadUri
    )

    $FHWebUri = 'https://www.fosshub.com'
    $FHApiUri = 'https://api.fosshub.com'

    Invoke-RestMethod -UseBasicParsing -Method GET -Uri "$FHApiUri/search/?q=$SearchTerm" | Select-Object -ExpandProperty data | Where-Object {$_.name -eq $SearchTerm } | ForEach-Object {
        $Response = Invoke-WebRequest -Uri "$FHWebUri/$($_.uri)"
        
        $ReleaseID = $Response.Content | Select-String -Pattern ('r":"([0-9a-zA-Z]+)') | Select-Object -ExpandProperty Matches | Select-Object -ExpandProperty Groups | Select-Object -ExpandProperty Value -Last 1
        $FileName = $Response.Content | Select-String -Pattern ("n`":`"($Filter)`"") | Select-Object -ExpandProperty Matches | Select-Object -ExpandProperty Groups | Select-Object -ExpandProperty Value -Last 1

        if ($DownloadUri.IsPresent) {
            $BodyData = @{
                "projectId" = $_._id
                "releaseId" = $ReleaseID
                "projectUri" = $_.uri
                "fileName" = $FileName
                "isLatestVersion" = $true
            }
            Invoke-RestMethod -Uri "$FHApiUri/download" -Method POST -Body $BodyData | Select-Object -ExpandProperty data | Select-Object -ExpandProperty url
        }
        else {
            ($FileName | Get-FirstRegexGroupValue -Pattern '([0-9\.]{2,})').Trim('.')
        }
    }
}