
<#
	.SYNOPSIS
		Keep a copy of al teardown quicksave game save files

	.DESCRIPTION
        Teardown keeps a quicksave, but only 1.

        This is bad if it corrupts or if you accidnetly save or you realise your save was a bad idea and need to go back 1 or more
    .PARAMETER Start
        How many seconds until we start checking for save files
        Necessary to wait for the game to start when starting the script before the game
    .PARAMETER Delay
        How many seconds between each check for a change.
    .NOTES
        1.0
            Continueally copy the file for reverting or corruption or failure
        TODO
            Limit the number of quicksaves so that the directory can self clean

#>

param (
    # Delay befpre starting the check
    [Alias('Start')][int] $check_start_delay = 30,

    # Delay between checks
    [Alias('Delay')][int] $check_interval_delay = 1
)
# Do not throw erros to screen
$ErrorActionPreference = 'SilentlyContinue'

# Return a file md5
function md5 ($file) {
    $crypto_service = New-Object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
    $md5_hash = [System.BitConverter]::ToString($crypto_service.ComputeHash([System.IO.File]::ReadAllBytes($file)))
    return $md5_hash
}
$old_md5 = $null

# Process name to check for
$process = "teardown"

# Get the red dead redemption 2 profile folders
$save_dir = [environment]::getfolderpath("mydocuments") + "\Teardown"
$save_file = $save_dir + "\quicksave.bin"
$save_file = ([System.IO.DirectoryInfo] ($save_dir + "\quicksave.bin"))

if (Test-Path $save_file) {
    $old_md5 = $(Get-FileHash $save_file).Hash
}

# Give time for the app to run
Start-Sleep $check_start_delay

# Check if the store directory already exists
if ( -not (Test-Path $save_dir"/quicksaves") ) {
    Write-Output "Creating quicksave dir $save_dir/quicksaves"
    New-Item -Path $save_dir -Name "quicksaves" -ItemType "directory" | Out-Null
}

# Run for as long as Teardown is running
while ( $null -ne $(Get-Process $process -ErrorAction SilentlyContinue) ) {
    Start-Sleep $check_interval_delay

    # Test for a quicksave file
    if (Test-Path $save_file) {

        # Cache its md5
        try {
            $new_md5 = $(Get-FileHash $save_file)
        } catch {
            continue
        }

        # If the file is altered
        if ( $new_md5.Hash -ne $old_md5) {
            # Cache the new md5
            $old_md5 = $new_md5.Hash

            # Create new new file path
            $timestamp = $(Get-Date -Format "yyyy.MM.dd-HH.mm.ss.fff")
            $new_file = $save_dir + "/quicksaves/quicksave." + $timestamp + ".bin"

            # Copy file to quicksave dir
            try {
                #Copy-Item $save_file -Destination $new_file

                # Safer?
                $image_bytes = [System.IO.File]::ReadAllBytes($save_file.FullName)
                [System.IO.File]::WriteAllBytes($new_file, $image_bytes)
            } catch {
                echo "Failed to copy"
                continue
            }

            Write-Output "File changed, creating new file $new_file"
        }
    } 
}

Write-Host "$process is no longer running"