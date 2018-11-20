Set-ScriptSettings {
    $RegistryPath = ''
    if (-not ($RegistryPath)) {
        New-Item -ItemType Container -Path $RegistryPath -Force
    }
    # ApplicationShare specifies where to look for XMLFileName
    Set-ItemProperty -Path $RegistryPath -Name 'ApplicationShare' -Value ''
    # XMLFileName contains the name of the file which holds information about what to do
    Set-ItemProperty -Path $RegistryPath -Name 'XMLFileName' -Value 'AppInfo.xml'
    # PSADTSource is used when parameter -DoDownload is specified
    # Points to a folder that contains PSADT
    Set-ItemProperty -Path $RegistryPath -Name 'PSADTSource' -Value ''
    # TeamsWebhookUri is used when parameter -SendToTeams is used
    # The uri is created when adding a webhook to a team in Microsoft Teams
    Set-ItemProperty -Path $RegistryPath -Name 'TeamsWebhookUri' -Value ''
}