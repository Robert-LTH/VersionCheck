function Global:Read-AppInfoXMLFile {
    param(
        [Parameter(Mandatory=$true,
                   Position=0,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [string]$FullName
    )
    process {
        #Write-LogEntry -Component $MyInvocation.MyCommand -FileName $Global:LogFileName -Severity 1 -Value "[Read-AppInfoXMLFile] Will process '$FullName'"
        try {
            $obj = New-Object PSObject
            $obj | Add-Member XML ([xml](Get-Content -Raw -ErrorAction Stop -Path $FullName))
            $obj | Add-Member Path (Split-Path -Path $FullName -Parent)
            $obj | Add-Member Name (Split-Path -Path $obj.Path -Leaf)
            #Write-LogEntry -Component $MyInvocation.MyCommand -FileName $Global:LogFileName -Severity 1 -Value "[Read-AppInfoXMLFile] Done processing '$FullName'"
            $obj
        } catch {
            Write-LogEntry -Component $MyInvocation.MyCommand -FileName $Global:LogFileName -Severity 3 -Value "[Read-AppInfoXMLFile] Failed to process '$FullName'"
        }
    }
}