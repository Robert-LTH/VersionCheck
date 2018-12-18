﻿<#
.SYNOPSIS
	This script performs the installation or uninstallation of an application(s).
	# LICENSE #
	PowerShell App Deployment Toolkit - Provides a set of functions to perform common application deployment tasks on Windows. 
	Copyright (C) 2017 - Sean Lillis, Dan Cunningham, Muhammad Mashwani, Aman Motazedian.
	This program is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation, either version 3 of the License, or any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details. 
	You should have received a copy of the GNU Lesser General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.
.DESCRIPTION
	The script is provided as a template to perform an install or uninstall of an application(s).
	The script either performs an "Install" deployment type or an "Uninstall" deployment type.
	The install deployment type is broken down into 3 main sections/phases: Pre-Install, Install, and Post-Install.
	The script dot-sources the AppDeployToolkitMain.ps1 script which contains the logic and functions required to install or uninstall an application.
.PARAMETER DeploymentType
	The type of deployment to perform. Default is: Install.
.PARAMETER DeployMode
	Specifies whether the installation should be run in Interactive, Silent, or NonInteractive mode. Default is: Interactive. Options: Interactive = Shows dialogs, Silent = No dialogs, NonInteractive = Very silent, i.e. no blocking apps. NonInteractive mode is automatically set if it is detected that the process is not user interactive.
.PARAMETER AllowRebootPassThru
	Allows the 3010 return code (requires restart) to be passed back to the parent process (e.g. SCCM) if detected from an installation. If 3010 is passed back to SCCM, a reboot prompt will be triggered.
.PARAMETER TerminalServerMode
	Changes to "user install mode" and back to "user execute mode" for installing/uninstalling applications for Remote Destkop Session Hosts/Citrix servers.
.PARAMETER DisableLogging
	Disables logging to file for the script. Default is: $false.
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -DeployMode 'Silent'; Exit $LastExitCode }"
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -AllowRebootPassThru; Exit $LastExitCode }"
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -DeploymentType 'Uninstall'; Exit $LastExitCode }"
.EXAMPLE
    Deploy-Application.exe -DeploymentType "Install" -DeployMode "Silent"
.NOTES
	Toolkit Exit Code Ranges:
	60000 - 68999: Reserved for built-in exit codes in Deploy-Application.ps1, Deploy-Application.exe, and AppDeployToolkitMain.ps1
	69000 - 69999: Recommended for user customized exit codes in Deploy-Application.ps1
	70000 - 79999: Recommended for user customized exit codes in AppDeployToolkitExtensions.ps1
.LINK 
	http://psappdeploytoolkit.com
#>
[CmdletBinding()]
Param (
	[Parameter(Mandatory=$false)]
	[ValidateSet('Install','Uninstall')]
	[string]$DeploymentType = 'Install',
	[Parameter(Mandatory=$false)]
	[ValidateSet('Interactive','Silent','NonInteractive')]
	[string]$DeployMode = 'Interactive',
	[Parameter(Mandatory=$false)]
	[switch]$AllowRebootPassThru = $false,
	[Parameter(Mandatory=$false)]
	[switch]$TerminalServerMode = $false,
	[Parameter(Mandatory=$false)]
	[switch]$DisableLogging = $false
)

Try {
	## Set the script execution policy for this process
	Try { Set-ExecutionPolicy -ExecutionPolicy 'ByPass' -Scope 'Process' -Force -ErrorAction 'Stop' } Catch {}
	
	##*===============================================
	##* VARIABLE DECLARATION
	##*===============================================
	## Variables: Application
	[string]$appVendor = ''
	[string]$appName = 'Git for windows'
	[string]$appVersion = ''
	[string]$appArch = ''
	[string]$appLang = 'EN'
	[string]$appRevision = '01'
	[string]$appScriptVersion = '1.0.0'
	[string]$appScriptDate = '2018-06-18'
	[string]$appScriptAuthor = 'Robert Johnsson Lunds universitet'
	##*===============================================
	## Variables: Install Titles (Only set here to override defaults set by the toolkit)
	[string]$installName = ''
	[string]$installTitle = ''
	
	##* Do not modify section below
	#region DoNotModify
	
	## Variables: Exit Code
	[int32]$mainExitCode = 0
	
	## Variables: Script
	[string]$deployAppScriptFriendlyName = 'Deploy Application'
	[version]$deployAppScriptVersion = [version]'3.7.0'
	[string]$deployAppScriptDate = '02/13/2018'
	[hashtable]$deployAppScriptParameters = $psBoundParameters
	
	## Variables: Environment
	If (Test-Path -LiteralPath 'variable:HostInvocation') { $InvocationInfo = $HostInvocation } Else { $InvocationInfo = $MyInvocation }
	[string]$scriptDirectory = Split-Path -Path $InvocationInfo.MyCommand.Definition -Parent
	
	## Dot source the required App Deploy Toolkit Functions
	Try {
		[string]$moduleAppDeployToolkitMain = "$scriptDirectory\AppDeployToolkit\AppDeployToolkitMain.ps1"
		If (-not (Test-Path -LiteralPath $moduleAppDeployToolkitMain -PathType 'Leaf')) { Throw "Module does not exist at the specified location [$moduleAppDeployToolkitMain]." }
		If ($DisableLogging) { . $moduleAppDeployToolkitMain -DisableLogging } Else { . $moduleAppDeployToolkitMain }
	}
	Catch {
		If ($mainExitCode -eq 0){ [int32]$mainExitCode = 60008 }
		Write-Error -Message "Module [$moduleAppDeployToolkitMain] failed to load: `n$($_.Exception.Message)`n `n$($_.InvocationInfo.PositionMessage)" -ErrorAction 'Continue'
		## Exit the script, returning the exit code to SCCM
		If (Test-Path -LiteralPath 'variable:HostInvocation') { $script:ExitCode = $mainExitCode; Exit } Else { Exit $mainExitCode }
	}
	
	#endregion
	##* Do not modify section above
	##*===============================================
	##* END VARIABLE DECLARATION
	##*===============================================
		
	If ($deploymentType -ine 'Uninstall') {
		##*===============================================
		##* PRE-INSTALLATION
		##*===============================================
		[string]$installPhase = 'Pre-Installation'

		## Show Welcome Message, close Internet Explorer if required, allow up to 3 deferrals, verify there is enough disk space to complete the install, and persist the prompt
		Show-InstallationWelcome -CloseApps 'git-bash,git-cmd,bash,git,sh,git,git-gui,gitk,git-lfs,mintty' -AllowDeferCloseApps -DeferTimes 3 -CheckDiskSpace
		
		## Show Progress Message (with the default message)
		Show-InstallationProgress
		
		## <Perform Pre-Installation tasks here>
		
		
		##*===============================================
		##* INSTALLATION 
		##*===============================================
		[string]$installPhase = 'Installation'
		
		## Handle Zero-Config MSI Installations
		If ($useDefaultMsi) {
			[hashtable]$ExecuteDefaultMSISplat =  @{ Action = 'Install'; Path = $defaultMsiFile }; If ($defaultMstFile) { $ExecuteDefaultMSISplat.Add('Transform', $defaultMstFile) }
			Execute-MSI @ExecuteDefaultMSISplat; If ($defaultMspFiles) { $defaultMspFiles | ForEach-Object { Execute-MSI -Action 'Patch' -Path $_ } }
		}
		
		## <Perform Installation tasks here>
		Get-ChildItem -Path "$dirFiles" -Filter "Git-*-64-bit.exe" | ForEach-Object {
			Execute-Process -Path $_.FullName -Parameters "/SP- /VERYSILENT /SUPPRESSMSGBOXES /LOG=`"C:\windows\logs\software\Git-64-bit-install.log`" /NORESTART /NOCLOSEAPPLICATIONS /LOADINF='$dirFiles\git.ans' /NOICONS"
		}
		
		##*===============================================
		##* POST-INSTALLATION
		##*===============================================
		[string]$installPhase = 'Post-Installation'
		
		## <Perform Post-Installation tasks here>
		New-Shortcut -Path "$envCommonStartMenuPrograms\Git (CMD).lnk" -TargetPath "$envProgramFiles\Git\git-cmd.exe"
		New-Shortcut -Path "$envCommonStartMenuPrograms\Git (bash).lnk" -TargetPath "$envProgramFiles\Git\git-bash.exe"

		## Display a message at the end of the install
		#If (-not $useDefaultMsi) { Show-InstallationPrompt -Message "$appVendor $appName $appVersion installerades." -ButtonRightText 'OK' -Icon Information -NoWait }
	}
	ElseIf ($deploymentType -ieq 'Uninstall')
	{
		##*===============================================
		##* PRE-UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Pre-Uninstallation'
		
		## Show Welcome Message, close Internet Explorer with a 60 second countdown before automatically closing
		Show-InstallationWelcome -CloseApps 'git-bash,git-cmd,bash,git,sh,git,git-gui,gitk,git-lfs,mintty' -AllowDeferCloseApps -DeferTimes 3 -CheckDiskSpace
		
		## Show Progress Message (with the default message)
		Show-InstallationProgress
		
		## <Perform Pre-Uninstallation tasks here>
		
		
		##*===============================================
		##* UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Uninstallation'
		
		## Handle Zero-Config MSI Uninstallations
		If ($useDefaultMsi) {
			[hashtable]$ExecuteDefaultMSISplat =  @{ Action = 'Uninstall'; Path = $defaultMsiFile }; If ($defaultMstFile) { $ExecuteDefaultMSISplat.Add('Transform', $defaultMstFile) }
			Execute-MSI @ExecuteDefaultMSISplat
		}
		
		# <Perform Uninstallation tasks here>
		Get-ChildItem -Path "$envProgramFiles\Git" -Filter "unins*.exe" | ForEach-Object {
			Execute-Process -Path $_.FullName -Parameters "/SP- /VERYSILENT /SUPPRESSMSGBOXES /LOG=`"C:\windows\logs\software\Git-64-bit-uninstall.log`" /NORESTART /NOCLOSEAPPLICATIONS"
		}
		
		##*===============================================
		##* POST-UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Post-Uninstallation'
		
		## <Perform Post-Uninstallation tasks here>
		Remove-Folder -Path 'C:\Program Files\Git'
		Remove-File -Path "$envCommonStartMenuPrograms\Git (bash).lnk"
		Remove-File -Path "$envCommonStartMenuPrograms\Git (cmd).lnk"
	}
	
	##*===============================================
	##* END SCRIPT BODY
	##*===============================================
	
	## Call the Exit-Script function to perform final cleanup operations
	Exit-Script -ExitCode $mainExitCode
}
Catch {
	[int32]$mainExitCode = 60001
	[string]$mainErrorMessage = "$(Resolve-Error)"
	Write-Log -Message $mainErrorMessage -Severity 3 -Source $deployAppScriptFriendlyName
	Show-DialogBox -Text $mainErrorMessage -Icon 'Stop'
	Exit-Script -ExitCode $mainExitCode
}
# SIG # Begin signature block
# MIIG5gYJKoZIhvcNAQcCoIIG1zCCBtMCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUZzGuUnFNWrhp0f36umj370PC
# hhagggQAMIID/DCCAuSgAwIBAgIJAO5U79VnHqDRMA0GCSqGSIb3DQEBCwUAMIGg
# MQswCQYDVQQGEwJTRTEMMAoGA1UECAwDIiAiMRowGAYDVQQKDBFMdW5kcyB1bml2
# ZXJzaXRldDEeMBwGA1UECwwVRGF0b3JkcmlmdGdydXBwZW4gTFRIMSIwIAYDVQQD
# DBlEYXRvcmRyaWZ0Z3J1cHBlbiBMVEggQ0EzMSMwIQYJKoZIhvcNAQkBFhRjZXJ0
# LWF1dGhAZGRnLmx0aC5zZTAeFw0xNzEwMjQxNDAwMTVaFw0yMjEwMjMxNDAwMTVa
# MGMxCzAJBgNVBAYTAlNFMRowGAYDVQQKExFMdW5kcyB1bml2ZXJzaXRldDEeMBwG
# A1UECxMVRGF0b3JkcmlmdGdydXBwZW4gTFRIMRgwFgYDVQQDEw9Sb2JlcnQgSm9o
# bnNzb24wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCrcj/KRJQOdHp2
# qReAK/4I3OyUL7301+z6X8Ci5c3aQRArXkY31uYJ9O4eS8v9yuSSrAs927giEp2C
# 2FTFxzYJWyglTKDrWsAFlGgkM5DUuiQ0qfILbXSHRG5vEgyIZamMym65CSm87D4l
# OuxTxTNv+hJ5v5wR+9Ioec1UH49/InxKrAcqI7HV8it18bGzAMGka0UgINuQ1xQr
# /m6FJ7YNw0Z4KH1pNxH7qf/Hs5RnJFFN9Aw4WEPTkuZ0LwbQYm2/s/Yu+XM9S8Qz
# 3zgwGvPqSXa+CLu4rcJs2Ig9x4hMwzsL2z8X16k5H/evqe+pHcKc4bfT/s7f+dTD
# I+z8YrtbAgMBAAGjdTBzMA4GA1UdDwEB/wQEAwIHgDAJBgNVHRMEAjAAMBYGA1Ud
# JQEB/wQMMAoGCCsGAQUFBwMDMB0GA1UdDgQWBBRXT748LxZOgzxfGiFJHyxk7TYz
# tzAfBgNVHSMEGDAWgBTUREp7/SpA2dVwFVbl8bjpQh6fqDANBgkqhkiG9w0BAQsF
# AAOCAQEATyI/AwH7b6pun8YOiHVurUD1or/gnh0V7l/AjTmL4cvzAeP89DoOmWv7
# uw9v2B0h22C94nyZYbURols6tISAY3g0w/2NweBD5S2jRsba9b2+Rs4i5hRNPIbG
# eZ25aSkFCEggqCwfnPguRJdTIUiAwS+QWKY4r219/jNlr1W+ebCuvXGf8noUbpS4
# 7e2PJl6q4KHXiowtnW6XCMSGeIs4wNH0uRzNKIkM5BMwh6COCp8A8h7Vm6IBwAVA
# Bwz1b7zzmyEaewbIYw5nO3B95O/eO3mljhpGPx8PNhYAZqmcCR0DMDcdJkcFv1nB
# 2CcDJxXxFFAG6UFYeJgZLZv6Z+RllzGCAlAwggJMAgEBMIGuMIGgMQswCQYDVQQG
# EwJTRTEMMAoGA1UECAwDIiAiMRowGAYDVQQKDBFMdW5kcyB1bml2ZXJzaXRldDEe
# MBwGA1UECwwVRGF0b3JkcmlmdGdydXBwZW4gTFRIMSIwIAYDVQQDDBlEYXRvcmRy
# aWZ0Z3J1cHBlbiBMVEggQ0EzMSMwIQYJKoZIhvcNAQkBFhRjZXJ0LWF1dGhAZGRn
# Lmx0aC5zZQIJAO5U79VnHqDRMAkGBSsOAwIaBQCgeDAYBgorBgEEAYI3AgEMMQow
# CKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisGAQQBgjcC
# AQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBTWSTHaQq/z9Tc0tFs4
# 6KCbwsn2mzANBgkqhkiG9w0BAQEFAASCAQBRqOrbk+87HwZcAx49r7SReP53DNNW
# /tUo4p5lBeKzmZa33aR7spPLojHsFL7ZY2K/IZ/4jzd2QlRZW9fATLNgMfb2Ox/k
# 4mePSxP+fhg/MavHYRRXn0PIUWP1/Rq9Ywok4ysEd4QNvp8FUuV+tL1GSBsjoGX3
# a6sIEw4ccYz19cEDK5JQ0ihSWl7oNfjqTBECWylttQQ7SlefGfPkZ7iL7AFRrjVr
# kSURPuiSoSxWY91Rl/iPZKay0yJUdAdeOdA4Fto5kEPHlBvHPbPnpdjCdub1vqZ8
# HFY0HYKoxcXhosihscMx1EiQ5/Cz8LDSugkDXSWfzRxIQevuq4tnEUWp
# SIG # End signature block