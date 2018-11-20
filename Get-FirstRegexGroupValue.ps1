function Global:Get-FirstRegexGroupValue {
    param(
        [Parameter(Mandatory=$true, 
                   ValueFromPipeline=$true)]
        [string]$Content,
        [string]$Pattern
    )
    $Content | Select-String -Pattern $Pattern | Select-Object -ExpandProperty Matches | Select-Object -ExpandProperty Groups | Select-Object -Last 1 -ExpandProperty Value
}