Add-Type -AssemblyName System.Drawing

function Resize-And-Compress {
    param (
        [string]$inputFile,
        [int]$targetWidth,
        [int]$quality,
        [string]$outputFile
    )

    $original = [System.Drawing.Image]::FromFile($inputFile)

    # Maintain aspect ratio
    $ratio = $original.Width / $original.Height
    $targetHeight = [math]::Round($targetWidth / $ratio)

    $bitmap = New-Object System.Drawing.Bitmap $targetWidth, $targetHeight
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.InterpolationMode = "HighQualityBicubic"
    $graphics.DrawImage($original, 0, 0, $targetWidth, $targetHeight)
    $graphics.Dispose()

    $encoder = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object {$_.MimeType -eq 'image/jpeg'}
    $params = New-Object System.Drawing.Imaging.EncoderParameters(1)
    $params.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, $quality)

    $bitmap.Save($outputFile, $encoder, $params)
    $bitmap.Dispose()
    $original.Dispose()

    Write-Host "Saved $outputFile (Width=$targetWidth, Quality=$quality)"
}

# --- Folder Paths ---
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
    #$ext = [System.IO.Path]::GetExtension($file).ToLower()
   # if ($ext -ne ".jpg" -and $ext -ne ".jpeg") {
    #    $img = [System.Drawing.Image]::FromFile($file)
    #    $tempFile = $file + ".jpg"
    #    $img.Save($tempFile, [System.Drawing.Imaging.ImageFormat]::Jpeg)
    #    $img.Dispose()
    #    $file = $tempFile
    #}

    $name = [System.IO.Path]::GetFileNameWithoutExtension($file)

    Resize-And-Compress $file 1900 86 "$folder300\$name 300kb.jpg"   # ~300 KB
    Resize-And-Compress $file 2200 89 "$folder500\$name 500kb.jpg"   # ~500 KB
    Resize-And-Compress $file 2400 91 "$folder700\$name 700kb.jpg"   # ~700 KB
}

Write-Host "Watching folder... Press Ctrl+C to stop"
while ($true) { Start-Sleep -Seconds 1 }