# Set console output encoding to UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Get the current directory path
$folderPath = Get-Location

# Define audio extensions to scan
$extensions = @("*.mp3", "*.flac", "*.wav", "*.m4a", "*.wma", "*.aac", "*.ogg")

Write-Host "Scanning folder: $($folderPath.Path)" -ForegroundColor Cyan

# --- FIX START ---
# We use Where-Object to filter extensions instead of -Include
# This is much more reliable for non-recursive scans.
$files = Get-ChildItem -Path $folderPath -File | Where-Object { 
    $fileName = $_.Name
    # Check if file name matches any of the extensions
    ($extensions | Where-Object { $fileName -like $_ })
}
# --- FIX END ---

$count = $files.Count
if ($count -eq 0) {
    Write-Warning "No audio files found in this directory."
    Write-Host "Extensions checked: $($extensions -join ', ')"
    Read-Host "Press Enter to exit..."
    exit
} else {
    Write-Host "Found $count audio file(s). Reading metadata..." -ForegroundColor Yellow
}

# Create Shell.Application object to read file properties
$shell = New-Object -ComObject Shell.Application
$folder = $shell.NameSpace($folderPath.Path)

# Find the index ID for the "Title" attribute
$titleIndex = -1
for ($i = 0; $i -lt 300; $i++) {
    $headerName = $folder.GetDetailsOf($null, $i)
    if ($headerName -eq "Title") {
        $titleIndex = $i
        break
    }
}

# Fallback for non-English Windows
if ($titleIndex -eq -1) {
    $titleIndex = 21 # Common index for Title
}

# List to store song data
$songList = @()

# Loop through files
$counter = 0

foreach ($file in $files) {
    $counter++
    # Update progress bar
    if ($counter % 5 -eq 0) {
        Write-Progress -Activity "Reading Metadata" -Status "Processing: $($file.Name)" -PercentComplete (($counter / $count) * 100)
    }

    # Parse file using Shell object
    $folderItem = $folder.ParseName($file.Name)
    
    if ($folderItem) {
        # Get the Title metadata
        $metaTitle = $folder.GetDetailsOf($folderItem, $titleIndex)
        
        # If metadata Title is empty, use filename as fallback to avoid false positives
        $cleanTitle = ""
        if ([string]::IsNullOrWhiteSpace($metaTitle)) {
            $cleanTitle = "[NO_TAG] " + $file.BaseName
        } else {
            $cleanTitle = $metaTitle.Trim()
        }

        # Add to object list
        $songList += [PSCustomObject]@{
            FileName = $file.Name
            SongTitle = $cleanTitle
        }
    }
}
Write-Progress -Activity "Reading Metadata" -Completed

# Group by SongTitle and find duplicates
$duplicates = $songList | Group-Object SongTitle | Where-Object { $_.Count -gt 1 }

# Output results
if ($duplicates) {
    Write-Host "`n=== DUPLICATE TITLES FOUND ===" -ForegroundColor Red
    
    foreach ($group in $duplicates) {
        Write-Host "`nTitle: [$($group.Name)] (Count: $($group.Count))" -ForegroundColor Magenta
        foreach ($item in $group.Group) {
            Write-Host "  -> File: $($item.FileName)" -ForegroundColor Gray
        }
    }
    
    Write-Host "`nScan complete."
} else {
    Write-Host "`nGood news! No duplicate song titles found." -ForegroundColor Green
}

# Pause execution
Write-Host "`n"
Read-Host "Press Enter to exit..."
