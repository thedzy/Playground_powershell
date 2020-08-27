
<#
#
	.SYNOPSIS
		Copy all the in game (Red Dead Redemption 2) photo mode file to a folder in jpeg format.

	.DESCRIPTION
        So, the game takes photos in game and stored them.  I just wanted and easy way to see the photos in order to send them via social media.
        
        The script trims off the propriatry header of Rock Star to make the photos a raw jpeg
        The script copies those files to a folder in the profile and calls it images
        The sxipt comments the file with the original file name
#>

# Get the red dead redemption profile folders
$documents = [environment]::getfolderpath("mydocuments") 
$profiles = $documents + "/Rockstar Games/Red Dead Redemption 2/Profiles"

Write-Host $profiles

foreach ($image_file in Get-ChildItem -Include "prdr*" -Exclude "*.jpeg" -Path $profiles -Recurse | Sort-Object CreationTime -Descending) {
    Write-Host $image_file.FullName

    # Copy file with a jpeg extension
    #Copy-Item -Path $image_file -Destination ($image_file.FullName + ".jpeg")

    $new_path = (New-Item -Path $image_file.PSParentPath -Name "Images" -Force -ItemType "Directory")
    $image_new_file = ($new_path.FullName + "\" + $image_file.CreationTime.ToFileTimeUtc() + ".jpeg")

    # Trim off header created by game
    if (Test-Path $image_new_file) {
        Write-Host "Already Converted"
    } else {
        # Trim header created by rockstar
        $image_temp = ("$env:TMP\{0}" -f $image_file.Name)
        $image_bytes = [System.IO.File]::ReadAllBytes($image_file.FullName)
        [System.IO.File]::WriteAllBytes($image_temp, $image_bytes[300..($image_bytes.count - 1)])

        # Attached comment exif data to indicate the source file
        $image_data = [System.Drawing.Image]::Fromfile($image_temp)
        $image_property = $image_data.PropertyItems[0]

        # Create comment property and write
        $image_property.id = 37510
        $image_property.Type = 2
        $image_property.value = $image_file.FullName.ToCharArray()
        $image_data.SetPropertyItem($image_property)

        # Save and release file resource
        $image_data.Save($image_new_file)
        $image_data.Dispose()
        
        # Clean up temp file
        Remove-Item -Path $image_temp

        Write-Host "Converted"
    }
}

Write-Host "Done"