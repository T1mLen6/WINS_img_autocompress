Add-Type -AssemblyName System.Drawing

function Compress-To-TargetSize {
    param (
        [string]$inputFile,
        [int]$targetKB,
        [string]$outputFile
    )

    $img = [System.Drawing.Image]::FromFile($inputFile)
    $encoder = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object {$_.MimeType -eq 'image/jpeg'}
    $params = New-Object System.Drawing.Imaging.EncoderParameters(1)

    $quality = 90
    while ($true) {
        $ms = New-Object System.IO.MemoryStream
        $params.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, $quality)
        $img.Save($ms, $encoder, $params)

        $sizeKB = [math]::Round($ms.Length / 1KB, 0)

        if ($sizeKB -le $targetKB -or $quality -le 5) {
            $ms.Position = 0
            $fs = [System.IO.File]::Create($outputFile)
            $ms.CopyTo($fs)
            $fs.Close()
            Write-Host "✔ Saved $outputFile ($sizeKB KB, quality=$quality)"
            break
        }

        $quality -= 5
    }
    $img.Dispose()
}

# --- Folder Watcher ---
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = "C:\Path\To\Images"   # <-- Change to your folder
$watcher.Filter = "*.*"
$watcher.IncludeSubdirectories = $false
$watcher.EnableRaisingEvents = $true

Register-ObjectEvent $watcher Created -Action {
    Start-Sleep -Seconds 1
    $file = $Event.SourceEventArgs.FullPath

    # Convert non-JPG files to JPG temp file
    $ext = [System.IO.Path]::GetExtension($file).ToLower()
    if ($ext -ne ".jpg" -and $ext -ne ".jpeg") {
        $img = [System.Drawing.Image]::FromFile($file)
        $tempFile = $file + ".jpg"
        $img.Save($tempFile, [System.Drawing.Imaging.ImageFormat]::Jpeg)
        $img.Dispose()
        $file = $tempFile
    }

    $base = [System.IO.Path]::GetFileNameWithoutExtension($file)
    $dir = [System.IO.Path]::GetDirectoryName($file)

    Compress-To-TargetSize $file 700 "$dir\$base`_700kb.jpg"
    Compress-To-TargetSize $file 500 "$dir\$base`_500kb.jpg"
    Compress-To-TargetSize $file 300 "$dir\$base`_300kb.jpg"
}

Write-Host "Watching folder... Press Ctrl+C to stop."
while ($true) { Start-Sleep -Seconds 1 }
