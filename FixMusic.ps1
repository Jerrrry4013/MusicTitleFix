# ==========================================
# CLEAN MUSIC SCRIPT (AUTO-GENERATED)
# ==========================================
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
if (-not $ScriptPath) { $ScriptPath = Get-Location }
Set-Location $ScriptPath

Write-Host "Running in: $ScriptPath" -ForegroundColor Cyan

$files = Get-ChildItem -Include *.m4a, *.flac, *.mp4, *.mp3 -File

# Define Special Characters via ID
$LeftBook   = [char]12298 
$RightBook  = [char]12299 
$LeftCorner = [char]12300 
$RightCorner= [char]12301 
$LeftBlock  = [char]12304 
$RightBlock = [char]12305 
$LeftQuote  = [char]8220  
$RightQuote = [char]8221  
$Ch_LeftParen  = [char]65288 
$Ch_RightParen = [char]65289 

foreach ($file in $files) {
    $name = $file.BaseName
    $ext = $file.Extension
    $oldName = $name
    $matched = $false

    # 1. Remove [P...]
    $name = $name -replace '^\[P\d+\]', ''

    # 2. Try Extracting Title
    if ($name -match "$LeftBook(.+?)$RightBook") {
        $name = $matches[1]
        $matched = $true
    }
    elseif ($name -match "$LeftCorner(.+?)$RightCorner") {
        $name = $matches[1]
        $matched = $true
    }
    elseif ($name -match '『(.+?)』') {
        $name = $matches[1]
        $matched = $true
    }
    # Fix for double question marks (using single quotes to prevent syntax error)
    elseif ($name -match '\?\?(.+?)\?\?') {
        $name = $matches[1]
        $matched = $true
    }

    # 3. Cleaning Loop
    if (-not $matched) {
        # Remove Chinese Brackets
        $name = $name -replace "^$LeftBlock.+?$RightBlock", ''
        $name = $name -replace "$LeftBlock.+?$RightBlock$", ''

        # Remove Chinese Quotes
        if ($name.StartsWith($LeftQuote)) {
            $name = $name -replace "^$LeftQuote", ''
            $name = $name -replace "$RightQuote.*$", ''
        }

        # Remove (cover)
        $name = $name -replace "$Ch_LeftParen" + "cover" + "$Ch_RightParen", ''
        $name = $name -replace '\(cover\)', ''
        $name = $name -replace '\s-\s.*$', ''

        # Special Fixes
        if ($oldName -match 'MMD') { $name = $Str_Welcome }
        if ($oldName -match 'Chu~') { $name = $Str_SorryCute }
        if ($oldName -match 'Sn2KE') { $name = 'Snake' }
        if ($oldName -match 'YOASOBI') { $name = $Str_Idol }
    }

    # 4. Final Trim
    $name = $name.Trim()
    $name = $name.Trim([char]9889).Trim([char]10084).Trim([char]9825).Trim('?').Trim('_').Trim('-').Trim()

    # 5. Rename
    if ($name -ne $oldName -and $name.Length -gt 0) {
        $finalName = $name + $ext
        $targetPath = Join-Path $file.DirectoryName $finalName
        
        $i = 1
        while (Test-Path $targetPath) {
            $finalName = $name + "_$i" + $ext
            $targetPath = Join-Path $file.DirectoryName $finalName
            $i++
        }

        Try {
            Rename-Item -LiteralPath $file.FullName -NewName $finalName -ErrorAction Stop
            Write-Host "OK: $finalName" -ForegroundColor Green
        } Catch {
            Write-Host "Error renaming file." -ForegroundColor Red
        }
    }
}

Write-Host "Done. Closing in 5 seconds..."
Start-Sleep -Seconds 5
