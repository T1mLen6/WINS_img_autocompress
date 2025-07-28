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
            Write-Host "Saved"
            break
        }

        $quality -= 5
    }
    $img.Dispose()
}

# --- Folder Watcher ---
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = "C:\Users\Qcells\Documents\WINS_img_autocompress\stain_samples"   # <-- Change to your folder
$watcher.Filter = "*.*"
$watcher.IncludeSubdirectories = $false
$watcher.EnableRaisingEvents = $true

# Create output folders automatically
$parent = Split-Path $watcher.Path -Parent
$baseName = Split-Path $watcher.Path -Leaf
$folder300 = Join-Path $parent ($baseName + "_300kb")
$folder500 = Join-Path $parent ($baseName + "_500kb")
$folder700 = Join-Path $parent ($baseName + "_700kb")

foreach ($folder in @($folder300, $folder500, $folder700)) {
    if (!(Test-Path $folder)) { New-Item -ItemType Directory -Path $folder | Out-Null }
}

Register-ObjectEvent $watcher Created -Action {
    Start-Sleep -Seconds 1
    $file = $Event.SourceEventArgs.FullPath

    # Convert non-JPG to JPG
    $ext = [System.IO.Path]::GetExtension($file).ToLower()
    if ($ext -ne ".jpg" -and $ext -ne ".jpeg") {
        $img = [System.Drawing.Image]::FromFile($file)
        $tempFile = $file + ".jpg"
        $img.Save($tempFile, [System.Drawing.Imaging.ImageFormat]::Jpeg)
        $img.Dispose()
        $file = $tempFile
    }

    $name = [System.IO.Path]::GetFileNameWithoutExtension($file)

    Compress-To-TargetSize $file 300 "$folder300\$name.jpg"
    Compress-To-TargetSize $file 500 "$folder500\$name.jpg"
    Compress-To-TargetSize $file 700 "$folder700\$name.jpg"
}

Write-Host "Watching folder... Press Ctrl+C to stop."
while ($true) { Start-Sleep -Seconds 1 }