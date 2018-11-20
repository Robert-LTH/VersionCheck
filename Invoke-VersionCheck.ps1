function Global:Invoke-VersionCheck {
    param(
        [Parameter(Mandatory=$true,
                   Position=0,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true)]
        $InputObject
    )
    process {
        Write-LogEntry -Component $MyInvocation.MyCommand -FileName $Global:LogFileName -Severity 1 -Value "Checking version for '$($InputObject.Name)'"
        $InputObject | Add-Member UnknownVersion (Get-AppVersion -AppXmlInfo $InputObject.XML.application.version.unknown -Format $InputObject.XML.application.version.unknown.format)
        $InputObject | Add-Member KnownVersion (Get-AppVersion -AppXmlInfo $InputObject.XML.application.version.known -Path $InputObject.Path)
        if ($InputObject.UnknownVersion.String  -eq '0.0') {
            Write-LogEntry -Component $MyInvocation.MyCommand -FileName $Global:LogFileName -Severity 1 -Value "$($InputObject.Name) - Fail to read remote version!"
            $Global:VersionErrors += "$($InputObject.Name) - Fail to read remote version!"
        }
        if ($InputObject.UnknownVersion.Object -ne $InputObject.KnownVersion.Object) {
            Write-LogEntry -Component $MyInvocation.MyCommand -FileName $Global:LogFileName -Severity 1 -Value "'$($InputObject.Name)' - $($InputObject.UnknownVersion.String) != $($InputObject.KnownVersion.String)"
        }
        Write-Output $_
    }
}