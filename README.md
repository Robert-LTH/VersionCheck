# VersionCheck
A simple version crawler

Script that reads a xml-file and fetches information from the web about the latest available version for that application.

  - Download to a folder of your choice
  - Edit Set-ScriptSettings.ps1
  - Run Set-ScriptSettings.ps1
  - Run versionscript.ps1

Parameters
  - -SendToTeams - Creates a list with applications that has UnknownVersion > KnownVersion and sends it to a Teams WebHook
  - -Debug - Saves a transcript to $PSScriptRoot\Logs\transcript.log
  - -DoDownload -  Creates ApplicationShare\AppName\NewVersion and copies a PSADT to the folder, the setup-file is saved to the Files folder of PSADT.