# Get-RunningConfig

## Introduction
This script will SSH into all network devices (based on the accompanying 'inventory.csv' file) using the user's credentials. It will then pull the running configuration, compare it to the previously pulled running-config (if it exists) and back it up if they are different.

## Notes
The included 'inventory.csv' is just an example file and will need to be filled out by the user and saved in the same file location as the .ps1 script.

## Pre-Requisites
This script requires a machine with PowerShell 2.0 or newer, PuTTY Release Version 0.72 or newer (with the CLI tool Plink)

## Running

In the base directory with the accompanying `inventory.csv` file run:
```
.\Get-RunningConfig.ps1
```
Enter your credentials. The results will be in the 'Configurations' folder in the base directory. Each site will be listed in its own folder and each device at that site will be a text file inside that folder.
