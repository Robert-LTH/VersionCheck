function Global:New-VersionCard {
    param(
        $Versions,
        $SeenErrors
    )
    $Card = @{
        '@type' = "MessageCard"
	    '@context' = "http://schema.org/extensions"
        'summary' = "Found $($Versions.facts.Count - 1) new versions!"
        #'text' = 'Card text'
	    'themeColor' = "0078D7"
        sections = @()
        potentialActions = @()
    }
    if ($Versions) {
        $Card.sections += $Versions
    }
    if ($SeenErrors) {
        $Card.sections += $SeenErrors
    }
    $Card | ConvertTo-Json -Depth 10
}