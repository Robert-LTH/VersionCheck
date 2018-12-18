function Global:Get-FtpDirList {
    param(
        $Uri,
        $Credential
    )

    # Create a FTPWebRequest based on current Uri
    $ftpConn = [System.Net.FtpWebRequest]::Create($Uri)

    # Use the ListDiretory method
    $ftpConn.Method = [System.Net.WebRequestMethods+Ftp]::ListDirectoryDetails

    # Set this to be a textmode transfer
    $ftpConn.UseBinary = $true
    # Set passive transfer
    $ftpConn.UsePassive = $true
    # No need for keepalive, we want in and out
    $ftpConn.KeepAlive = $false
    # Timeout in milliseconds, 5 seconds should be enough to list a directory
    $ftpConn.Timeout = 5000

    $resp = $ftpConn.GetResponse()
    
    # Output the messages from the server
    Write-Verbose $resp.BannerMessage
    Write-Verbose $resp.WelcomeMessage
    Write-Verbose $resp.StatusDescription
    

    $stream = $resp.GetResponseStream()
    $StreamReader = New-Object System.IO.Streamreader $stream
    while (-not $StreamReader.EndOfStream) {
        $SplitRow = $StreamReader.ReadLine() -replace '[\ ]+',' ' -split ' '
        $obj = New-Object PSObject
        $obj | Add-Member -NotePropertyName Name -NotePropertyValue $SplitRow[8]
        $obj | Add-Member -NotePropertyName IsLink -NotePropertyValue ($SplitRow[0] -match '^l')
        $obj | Add-Member -NotePropertyName IsDirectory -NotePropertyValue ($SplitRow[0] -match '^d')
        $obj | Add-Member -NotePropertyName IsFile -NotePropertyValue ($SplitRow[0] -match '^-')
        $obj | Add-Member -NotePropertyName Path -NotePropertyValue ("$Uri/$($SplitRow[8])")
        $obj | Add-Member -NotePropertyName Content -NotePropertyValue $obj.Name
        $obj
    }
    $StreamReader.Close()
    $stream.Close()
    $resp.Close()
}