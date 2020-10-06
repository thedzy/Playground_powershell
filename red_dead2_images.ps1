
<#
	.SYNOPSIS
		Copy all the in game (Red Dead Redemption 2) photo mode file to a folder in jpeg format.

	.DESCRIPTION
        So, the game takes photos in game and stors them.  I just wanted and easy way to see the photos in order to send them via social media.
        
        The script trims off the propriatry header of Rock Star to make the photos a raw jpeg
        The script copies those files to a folder in the profile and calls it images
        The script comments the file with the original file name
    .PARAMETER remove
        Remove pictures after processing
        Added after I found that there is a limit on how many photos you can have
    .NOTES
        1.0
            Copy the file and strip the header off the file
        1.1
            Added options:
                Remove the file after successful processing
                Overwrite the existing files if present
            Changed to using modification time for new file name
            EXIF tag the date and programme name
#>

param (
    # Remove pictures after processing
    [switch] $remove = $false,

    # Remove pictures after processing
    [switch] $overwrite = $false
)

Add-Type -AssemblyName system.drawing

function Set-Exif {
    param (
        [string] $image_file,
        [int] $id = 0,
        $value,
        [int] $type = 2
    )

    if ($type -eq 2 ) {
        $value = $value.ToCharArray()
    }

    $image_bytes = [System.IO.File]::ReadAllBytes($image_file)
    $image_stream = New-Object IO.MemoryStream($image_bytes, 0, $image_bytes.Length)
    $image_data = [System.Drawing.Image]::FromStream($image_stream)

    $image_property = $image_data.PropertyItems[0]

    # Create exif attribute
    $image_property.id = $id
    $image_property.Type = $type
    $image_property.value = $value
    $image_property.len = $value.length
    $image_data.SetPropertyItem($image_property)

    # Save and release file resource
    $image_data.Save($image_file)
    $image_data.Dispose()
}

# Get the red dead redemption 2 profile folders
$documents = [environment]::getfolderpath("mydocuments") 
$profiles = $documents + "/Rockstar Games/Red Dead Redemption 2/Profiles"

Write-Host $profiles

foreach ($image_file in Get-ChildItem -Include "prdr*" -Exclude "*.jpeg" -Path $profiles -Recurse | Sort-Object CreationTime -Descending) {
    Write-Host $image_file.FullName

    # Copy file with a jpeg extension
    #Copy-Item -Path $image_file -Destination ($image_file.FullName + ".jpeg")

    $new_path = (New-Item -Path $image_file.PSParentPath -Name "Images" -Force -ItemType "Directory")
    $image_new_file = ($new_path.FullName + "\" + $image_file.LastWriteTime.ToFileTimeUtc() + ".jpeg")

    # Trim off header created by game
    if ((Test-Path $image_new_file) -And (-Not $overwrite)) {
        Write-Host "Already Converted"
    } else {
        try {
            # Trim header created by Rockstar
            $image_temp = ("$env:TMP\{0}" -f $image_file.Name)
            $image_bytes = [System.IO.File]::ReadAllBytes($image_file.FullName)
            [System.IO.File]::WriteAllBytes($image_temp, $image_bytes[300..($image_bytes.count - 1)])

            # EXIF DATA
            # Original date
            Set-Exif $image_temp -id 36867 -type 2 -value $image_file.LastWriteTime.ToString("yyyy:MM:dd HH:mm:ss")
            # Programme
            Set-Exif $image_temp -id 305 -type 2 -value "Red Dead Redemption 2"
            # Unique ID
            Set-Exif $image_temp -id 42016 -type 2 -value $image_file.Name
            # Comment/Original Path
            Set-Exif $image_temp -id 37510 -type 2 -value $image_file.FullName

            # Move the temp file to its file location
            Move-Item $image_temp $image_new_file -Force
            
            Write-Host "Converted"
        } catch {
            Write-Host "Error in converting or writing the file"
            $e = $_.Exception
            $line = $_.InvocationInfo.ScriptLineNumber
            $msg = $e.Message 

            Write-Host -ForegroundColor Red "caught exception: $e at $line"
        }
    }

    if ($remove) {
        if ($skip) {
            Write-Host "Leaving file"
        } else {
            Write-Host "Removing File"
            Remove-Item $image_file
        }
    }
}

Write-Host "Done"