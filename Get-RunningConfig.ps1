<#
.SYNOPSIS
Retrieves the running configuration from all networking devices

.DESCRIPTION
This script will SSH into all network devices (based on the accompanying 'inventory.csv' file) using the user's credentials.
It will then pull the running configuration, compare it to the previously pulled running-config (if it exists) and back it up
if they are different.

.NOTES
File Name		: Get-RunningConfig.ps1
Author			: Cadence James
Pre-Requisite	: PowerShell Version 2.0 or newer
				: PuTTY Release 0.72 or newer (with PLink)
				: 'inventory.csv' file
				: Network Device Credentials
#>


$username = Read-Host -Prompt "Username"
$password = Read-Host -Prompt "Password" -AsSecureString
$temppass = [System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($password)
$password = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($temppass)
if (! (Test-Path 'inventory.csv')) {
	write-host "No inventory file detected. Please verify" -foreground red
	exit
}
$inventory = Import-Csv -Path '.\inventory.csv'
$md5 = New-Object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
$utf8 = New-Object -TypeName System.Text.UTF8Encoding
$failedpings = New-Object System.Collections.Generic.List[System.Object]
$failedpingfile = '.\FailedPings.txt'
$counter = 1
$stopwatch = [Diagnostics.Stopwatch]::StartNew()
foreach ($device in $inventory) {
	Write-Host ""
	Write-Host "=====================================" -foreground Cyan
	Write-Host " $counter of ( $inventory.Count )" -foreground Cyan
	Write-Host " Gathering Config: ( $device.ip )" -foreground Cyan
	Write-Host "=====================================" -foreground Cyan
	Write-Host ""
	$config = $null
	$testconnection = Test-Connection ($device.ip) -Count 1 -Quiet
	if ($testconnection -eq $False) {
		$failedpings.Add("($device.ip) - Ping")
		Clear
		$counter++
		Continue
	}
	echo y | plink ($device.ip) -ssh
	$config =plink ($device.ip) -l $username -pw $password -batch "show run"
	if ($confing -eq $null) {
		$failedpings.Add("($device.ip) - Login")
		Clear
		$counter++
		Continue
	}
	$confighash = ([System.BitConverter]::ToString($md5.ComputeHash($utf8.GetBytes($config))))
	$output = '.\Configurations\($device.sitename)-($device.sitecode)-($device.octet)\($device.ip)-($device.hostname).txt'
	if (! (Test-Path -Path $output)) {
		New-Item -Path $output -type file -force | Out-Null
		Add-Content $output $config
		Add-Content $output $confighash
	}
	else {
		$oldconfig = Get-Content $output
		$oldconfighash = $oldconfig[-1]
		Write-Verbose "New Config Hash: $confighash"
		Write-Verbose "Old Config Hash: $oldconfighash"
		if ($oldconfighash -ne $confighash) {
			$outinfo = Get-Item $output
			$archviepath = "($outinfo.BaseName)_($outinfo.LastWriteTime.ToString('yyyy-MM-dd_HH-mm')).txt"
			$parent = Split-Path $output -Parent
			$destination = Join-Path $parent "ARCHIVE"
			if (! (Test-Path -Path $destination)) {
				New-Item -ItemType Directory -Path $destination | Out-Null
			}
			$destination = Join-Path $destination $archivepath
			Move-Item $output $destination
			New-Item -Path $output -Type file -Force | Out-Null
			Add-Content $output $config
			Add-Content $output $confighash
		}
		else {
			Write-Verbose "New Config is the same as the old config"
			Clear
			$counter++
			Continue
		}
	}
	Clear
	$counter++
}
New-Item -Path $failedpingfile -Type file -Force | Out-Null
Add-Content $failedpingfile $failedpings
$stopwatch.stop()
Sleep(1)
Clear
Write-Host ""
Write-Host " Script ran in ($stopwatch.Elapsed.Minutes) Minutes, ($stopwatch.Elapsed.Seconds) Seconds, ($stopwatch.Elapsed.Milliseconds) ms"
