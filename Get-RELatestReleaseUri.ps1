function Global:Get-RELatestReleaseUri {
    param(
        [System.Xml.XmlElement]$AppXmlInfo
    )
    $AppWebData = Invoke-FindInWebContent -AppXmlInfo $AppXmlInfo -ReturnUri
    #Write-LogEntry -Component $MyInvocation.MyCommand -FileName $Global:LogFileName -Severity 1 -Value "$AppWebData"
    if ($AppWebData.Length -and $AppWebData -notmatch '^http') {
        $Return = "$($AppXmlInfo.Uri.SubString(0,$AppXmlInfo.Uri.LastIndexOf('/')))/$($AppWebData)"
    }
    else {
        $Return = $AppWebData
    }
    #Write-LogEntry -Component $MyInvocation.MyCommand -FileName $Global:LogFileName -Severity 1 -Value "Uri: $Return"
    Write-Output $Return
}
