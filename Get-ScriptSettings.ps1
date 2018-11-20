function Global:Get-ScriptSettings {
    param(
        $RegistryPath
    )
    $SettingNames = @(
        'ApplicationShare'
        'XMLFileName'
        'PSADTSource'
        'TeamsWebhookUri'
    )
    $AppSettings = New-Object PSObject 
    $SettingNames | ForEach-Object {
        $CurrentItem = (Get-ItemProperty -ErrorAction SilentlyContinue -Path $RegistryPath -Name $_)."$_"
        if ($CurrentItem) {
            $AppSettings | Add-Member $_ $CurrentItem
        }
        else {
            throw "Failed to read setting '$_'"
        }
    }
    Write-Output $AppSettings
}