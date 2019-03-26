function Global:Get-WebFile {
    param(
        [string]$Uri,
        [string]$Destination,
        $Format
    )
    begin {
        $Return = $false
        try {
            Get-Item -Path $Destination -ErrorAction Stop | Out-Null
        } catch {
            throw "Get-WebFile: $_"
        }
    }
    process {
        $Return = $false
        try {
            $TempFileName = New-TemporaryFile
            $Uri = ([System.Net.WebUtility]::UrlDecode($Uri)) -replace '&amp;','&'
            #Write-LogEntry -Component $MyInvocation.MyCommand -Severity 1 -Value $TempFileName
            #Write-LogEntry -Component $MyInvocation.MyCommand -Severity 1 -Value ($TempFileName.GetType())
            #Write-LogEntry -Component $MyInvocation.MyCommand -Severity 1 -Value $Uri
            $SavedProgressPreference = $ProgressPreference
            $ProgressPreference = "SilentlyContinue"
            $Data = Invoke-WebRequest -ErrorAction Stop -Uri $Uri -UseBasicParsing -OutFile $TempFileName -PassThru
            $ProgressPreference = $SavedProgressPreference
            if ($Data.StatusCode -eq 200) {
                #Write-LogEntry -Component $MyInvocation.MyCommand -Severity 1 -Value  "Request was successful!"
                $Filename = Split-Path -Path $Uri -Leaf
                $BannedCharacters = '\?'
                if ($FileName -notmatch $BannedCharacters) {
                    #Write-LogEntry -Component $MyInvocation.MyCommand -Severity 1 -Value  "'$FileName' is clear for use"
                    $FileName = Split-Path -Path $Uri -Leaf
                    $Return = $true
                }
                elseif ($Filename -match $BannedCharacters) {
                    Write-LogEntry -Component $MyInvocation.MyCommand -Severity 2 -Value  "'$FileName' contains characters which are not allowed in filenames"
                    $Parameters = $FileName | Select-String -Pattern ([System.Net.WebUtility]::UrlDecode($Format.Pattern)) | Select-Object -ExpandProperty Matches | ForEach-Object { if ($_.Groups.Count -gt 1) { $_.Groups[1..($_.Groups.Count)] } else { $_.Groups } }#| Select-Object -ExpandProperty Value #-Last $($_.Count-1)
                    #Write-LogEntry -Component $MyInvocation.MyCommand -Severity 1 -Value "First parameter: $($Parameters)"
                    $Filename = $Format.string -f $Parameters.Value
                    if (-not ([string]::IsNullOrEmpty($Filename))) {
                        $Return = $true
                    }
                    else {
                        Write-LogEntry -Component $MyInvocation.MyCommand -Severity 3 -Value "'$FileName' No formatting done!"
                    }
                }
                if ([string]::IsNullOrEmpty(([IO.PATH]::GetExtension($Filename)))) {
                    # Guess that we have been redirected and use the last part of the uri
                    Write-LogEntry -Component $MyInvocation.MyCommand -Severity 2 -Value "No extension detected in filename, try to use ResponseUri ($($Data.BaseResponse.ResponseUri.OriginalString))"
                    $Filename = Split-Path -Path $Data.BaseResponse.ResponseUri.OriginalString -Leaf
                }
                try {
                    if ($Return) {
                        Write-LogEntry -Component $MyInvocation.MyCommand -Severity 1 -Value  "Everything looks good, moving '$($TempFileName)' to '$Destination\$FileName'"
                        Move-Item -Path $TempFileName -Destination "$Destination\$Filename" -Force -ErrorAction Stop
                    }
                } catch {
                    Write-LogEntry -Component $MyInvocation.MyCommand -Severity 3 -Value "Failed to move file with filename '$Filename': $_"
                    $Return = $false
                }
            }
            else {
                Write-LogEntry -Component $MyInvocation.MyCommand -Severity 3 -Value "Tried to fetch: '$Uri' but wrong StatusCode: $Data.Content"
            }
        } catch {
            Write-LogEntry -Component $MyInvocation.MyCommand -Severity 3 -Value "Tried to fetch: '$Uri' but something went wrong: $_"
        }
    }
    end {
        Remove-Item -ErrorAction SilentlyContinue -Force $TempFileName
        Write-Output $Return
    }
}