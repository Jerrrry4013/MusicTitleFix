[CmdletBinding()]
param(
    [switch]$Execute
)

$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$processedCount = 0
$skippedCount = 0
$errorCount = 0

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   MP3 Clean Tool" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if (-not $Execute) {
    Write-Host "[Preview Mode] Use -Execute to apply changes" -ForegroundColor Yellow
    Write-Host ""
}

$mp3Files = Get-ChildItem -Path . -Filter "*.mp3" -File

if ($mp3Files.Count -eq 0) {
    Write-Host "No MP3 files found" -ForegroundColor Yellow
    exit
}

Write-Host "Found $($mp3Files.Count) MP3 files" -ForegroundColor Green
Write-Host ""

foreach ($file in $mp3Files) {
    $oldName = $file.Name
    Write-Host "Processing: $oldName" -ForegroundColor White
    
    if ($oldName -match '^(.+?) - (.+?)\.mp3$') {
        $artist = $matches[1]
        $songNameRaw = $matches[2]
        
        $songName = $songNameRaw -replace '\s*\[.+?\]\s*$', ''
        $songName = $songName.Trim()
        
        $newName = "$songName.mp3"
        
        if ([string]::IsNullOrWhiteSpace($songName)) {
            Write-Host "  [SKIP] Invalid song name" -ForegroundColor Yellow
            $skippedCount++
            Write-Host ""
            continue
        }
        
        if ($newName -eq $oldName) {
            Write-Host "  [SKIP] Already in correct format" -ForegroundColor Gray
            $skippedCount++
            Write-Host ""
            continue
        }
        
        $targetPath = Join-Path -Path $file.DirectoryName -ChildPath $newName
        if ((Test-Path -LiteralPath $targetPath) -and ($targetPath -ne $file.FullName)) {
            Write-Host "  [ERROR] Target file already exists: $newName" -ForegroundColor Red
            $errorCount++
            Write-Host ""
            continue
        }
        
        Write-Host "  Artist: $artist" -ForegroundColor DarkGray
        Write-Host "  Song: $songName" -ForegroundColor DarkGray
        
        try {
            if ($Execute) {
                Rename-Item -LiteralPath $file.FullName -NewName $newName -ErrorAction Stop
                Write-Host "  [OK] Renamed to: $newName" -ForegroundColor Green
            } else {
                Write-Host "  [PREVIEW] Will rename to: $newName" -ForegroundColor Cyan
            }
            $processedCount++
        }
        catch {
            Write-Host "  [ERROR] $($_.Exception.Message)" -ForegroundColor Red
            $errorCount++
        }
    }
    else {
        Write-Host "  [SKIP] Name format not matched" -ForegroundColor Yellow
        $skippedCount++
    }
    
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Done" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Processed: $processedCount files" -ForegroundColor Green
Write-Host "Skipped: $skippedCount files" -ForegroundColor Yellow
Write-Host "Errors: $errorCount files" -ForegroundColor Red

if (-not $Execute -and $processedCount -gt 0) {
    Write-Host ""
    Write-Host "Run with -Execute to apply changes" -ForegroundColor Yellow
}
