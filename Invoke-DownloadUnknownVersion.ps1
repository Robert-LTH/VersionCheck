. "$PSScriptRoot\Get-RELatestReleaseUri.ps1"
. "$PSScriptRoot\Get-GHLatestRelease.ps1"
. "$PSScriptRoot\Get-FHLatestRelease.ps1"
. "$PSScriptRoot\Get-SFLatestReleaseUri.ps1"
. "$PSScriptRoot\Invoke-PreparePSADT.ps1"
. "$PSScriptRoot\Get-WebFile.ps1"

function Global:Invoke-DownloadUnknownVersion {
    param(
        [Parameter(Mandatory=$true,
            Position=0,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)]
        $InputObject,
        $Settings
    )
    process {
        Write-LogEntry -Component $MyInvocation.MyCommand -Severity 1 -Value "'$($InputObject.Name)'"
        $InputObject.XML.application.download | ForEach-Object {
            $CurrentElement = $_
            if ($CurrentElement.HasAttributes) {
                $DownloadType = $CurrentElement.Attributes[0].Value
            }
            else {
                $DownloadType = 'regex'
            }
            switch ($DownloadType) {
                'direct' {
                    $Uri = $CurrentElement.Uri
                }
                'github' {
                    # Do github stuff
                    #Write-LogEntry -Component $MyInvocation.MyCommand -FileName $Global:LogFileName -Severity 1 -Value "DownloadType: github"
                    $Uri = Get-GHLatestRelease -Owner $CurrentElement.Owner -Repository $CurrentElement.Repository -Filter $CurrentElement.Filter -DownloadUri
                    #return
                }
                'fosshub' {
                    # Do github stuff
                    #Write-LogEntry -Component $MyInvocation.MyCommand -FileName $Global:LogFileName -Severity 1 -Value "DownloadType: github"
                    $Uri = Get-FHLatestRelease -SearchTerm $CurrentElement.Project -Filter $CurrentElement.Filter -DownloadUri
                    #return
                }
                'sourceforge' {
                    # Do SF stuff
                    #Write-LogEntry -Component $MyInvocation.MyCommand -FileName $Global:LogFileName -Severity 1 -Value "DownloadType: sourceforge"
                    $Uri = Get-SFLatestReleaseUri -Project $CurrentElement.Project
                    #return
                }
                default {
                    #Write-LogEntry -Component $MyInvocation.MyCommand -FileName $Global:LogFileName -Severity 1 -Value "DownloadType: regularexpression"
                    $Uri = Get-RELatestReleaseUri -AppXmlInfo $CurrentElement
                }
            }
            if (-not $Uri) {
                Write-LogEntry -Component $MyInvocation.MyCommand -FileName $Global:LogFileName -Severity 3 -Value "Failed to get an Uri ($Uri) for $($InputObject.Name)"
                return
            }
            #Write-LogEntry -Component $MyInvocation.MyCommand -FileName $Global:LogFileName -Severity 1 -Value "Download Uri for $($InputObject.Name) is '$Uri'"

            $UnknownVersionFolder = "$($InputObject.Path)\$($InputObject.UnknownVersion.String)"
            $KnownVersionFolder = "$($InputObject.Path)\$($InputObject.KnownVersion.String)"

            if (-not (Test-Path -ErrorAction SilentlyContinue -Path $UnknownVersionFolder)) {
                Write-LogEntry -Component $MyInvocation.MyCommand -FileName $Global:LogFileName -Severity 1 -Value "Prepare PSADT ($($Settings.PSADTSource)) in '$UnknownVersionFolder'"
                Invoke-PreparePSADT -Destination $UnknownVersionFolder -PSADTSource $Settings.PSADTSource
                if ((Test-Path -ErrorAction SilentlyContinue -Path "$KnownVersionFolder\Deploy-Application.ps1")) {
                    Write-LogEntry -Component $MyInvocation.MyCommand -FileName $Global:LogFileName -Severity 1 -Value "Copy files from '$KnownVersionFolder'"
                    Copy-Item -Path "$KnownVersionFolder\Deploy-Application.ps1" -Destination $UnknownVersionFolder
                    Copy-Item -Path "$KnownVersionFolder\AppDeployToolkit\AppDeployToolkitConfig.xml" -Destination "$UnknownVersionFolder\AppDeployToolkit"
                    Copy-Item -Recurse -Path "$KnownVersionFolder\SupportFiles\*" -Destination "$UnknownVersionFolder\SupportFiles"
                }
            }
            else {
                Write-LogEntry -Severity 1 -Value "Folder '$UnknownVersionFolder' already exist, assuming this is an additional download."
            }

            #New-Item -ErrorAction Stop -ItemType Container -Path $UnknownVersionFolder\Files
            #Write-LogEntry -Component $MyInvocation.MyCommand -FileName $Global:LogFileName -Severity 1 -Value "[Invoke-DownloadUnknownVersion] Format pattern: $($InputObject.XML.application.download.format.pattern)"
            $Result = Get-WebFile -Uri $Uri -Destination "$UnknownVersionFolder\Files" -Format $InputObject.XML.application.download.format
            if (-not $Result) {
                Write-LogEntry -Component $MyInvocation.MyCommand -FileName $Global:LogFileName -Severity 3 -Value "Failed to get installation file. Cleaning '$UnknownVersionFolder'"
                Remove-Item -Force -Recurse -Path $UnknownVersionFolder
                Write-LogEntry -Component $MyInvocation.MyCommand -FileName $Global:LogFileName -Severity 1 -Value "Removed '$UnknownVersionFolder', aborting due to error."
                return
            }
            $UnknownVersionFiles = Get-ChildItem -Path "$UnknownVersionFolder\Files\" | Select-Object -ExpandProperty Name
            if ($UnknownVersionFiles.Count -eq 1 -and $UnknownVersionFiles -match '\.msp') {
                Write-LogEntry -Severity 1 -Value "The only file in the folder Files is '$UnknownVersionFiles', you might want to copy the full installation into the folder Files too."
            }
            Write-Output $InputObject
        }
    }
}