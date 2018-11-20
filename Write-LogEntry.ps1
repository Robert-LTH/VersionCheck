<#
	Copied from https://github.com/SCConfigMgr/ConfigMgr/blob/master/Operating%20System%20Deployment/Invoke-TPMOwnerPassword.ps1
#>
function Write-LogEntry {
	param(
		[parameter(Mandatory=$true, HelpMessage="Value added to the file specified as FileName.")]
		[ValidateNotNullOrEmpty()]
		[string]$Value,

		[parameter(Mandatory=$true, HelpMessage="Severity for the log entry. 1 for Informational, 2 for Warning and 3 for Error.")]
		[ValidateNotNullOrEmpty()]
        [ValidateSet("1", "2", "3")]
		[string]$Severity,

		[parameter(Mandatory=$false, HelpMessage="Severity for the log entry. 1 for Informational, 2 for Warning and 3 for Error.")]
		[ValidateNotNullOrEmpty()]
        [ValidateSet("CMLogEntry", "Vanilla", "WinEvent")]
		[string]$EntryType = "CMLogEntry",

		[parameter(Mandatory=$false, HelpMessage="Name of the log file that the entry will written to.")]
		[ValidateNotNullOrEmpty()]
		[string]$FileName = $(if (-not ($Global:LogFileName)) { "Write-LogEntry.log" } else { $Global:LogFileName }),

		[parameter(Mandatory=$false, HelpMessage="Name of the log file that the entry will written to.")]
		[ValidateNotNullOrEmpty()]
		[string]$Component = [IO.Path]::GetFileNameWithoutExtension($FileName),
		[switch]$ReturnPath
	)

	# Determine log file location
	try {
		$TSEnvironment = New-Object -ComObject Microsoft.SMS.TSEnvironment
		$LogFilePath = Join-Path -Path $TSEnvironment.Value("_SMSTSLogPath") -ChildPath $FileName
	} catch { 
		$LogDir = 'C:\Windows\Logs'
		if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
			$LogDir = "$PSScriptRoot\Logs"
		}
		$LogFilePath = Join-Path -Path $LogDir -ChildPath $FileName
		if (-not (Test-Path -Path $LogDir)) {
			New-Item -Path $LogDir -Force -ItemType Container
		}
	}
	if ($ReturnPath.IsPresent) {
		Write-Output $LogFilePath
	}
    # Construct time stamp for log entry
    $Time = -join @((Get-Date -Format "HH:mm:ss.fff"), "+", (Get-CimInstance -ClassName Win32_TimeZone | Select-Object -ExpandProperty Bias))

    # Construct date for log entry
    $Date = (Get-Date -Format "MM-dd-yyyy")

    # Construct context for log entry
    $Context = $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)

	# Construct final log entry
	switch ($EntryType) {
		'WinEvent' {
			Write-Warning "Not implemented yet!"
			$LogText = ''
		}
		'CMLogEntry' {
			$LogText = "<![LOG[$($Value)]LOG]!><time=""$($Time)"" date=""$($Date)"" component=""$($Component)"" context=""$($Context)"" type=""$($Severity)"" thread=""$($PID)"" file="""">"
		}
	}
	
	# Add value to log file
    try {
	    Add-Content -Value $LogText -LiteralPath $LogFilePath -ErrorAction Stop
    }
    catch [System.Exception] {
        Write-Warning -Message "Unable to append log entry to $FileName file"
    }
}