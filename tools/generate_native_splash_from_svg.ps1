<#
Script: generate_native_splash_from_svg.ps1
Purpose: Convert `assets/images/logo.svg` into PNGs for Android mipmap folders
Requirements: Inkscape CLI available in PATH. Place your SVG at `assets/images/logo.svg`.

Usage:
  powershell -ExecutionPolicy Bypass -File .\tools\generate_native_splash_from_svg.ps1

What it does:
  - Validates presence of SVG
  - Attempts to export PNGs for common Android densities
  - Places files in `android/app/src/main/res/mipmap-*/ic_splash_logo.png`
  - Updates `android/app/src/main/res/drawable/launch_background.xml` to reference `@mipmap/ic_splash_logo`

#>

Set-StrictMode -Version Latest

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
# projectRoot is the parent directory of the tools folder (project root)
$projectRoot = Split-Path -Parent $scriptDir
$svgPath = Join-Path $projectRoot 'assets\images\logo.svg'
if (-not (Test-Path $svgPath)) {
    Write-Error "SVG not found at $svgPath. Please add your logo SVG there and re-run this script.";
    exit 1
}

function Find-Inkscape {
    $ink = Get-Command inkscape -ErrorAction SilentlyContinue
    if ($ink) { return $ink.Path }
    # Try common locations (Windows)
    $possible = @(
        "$env:ProgramFiles\Inkscape\bin\inkscape.exe",
        "$env:ProgramFiles\Inkscape\inkscape.exe",
        "$env:ProgramFiles(x86)\Inkscape\bin\inkscape.exe",
        "$env:ProgramFiles(x86)\Inkscape\inkscape.exe",
        "$env:LOCALAPPDATA\Programs\Inkscape\bin\inkscape.exe",
        "$env:LOCALAPPDATA\Programs\Inkscape\inkscape.exe"
    )
    foreach ($p in $possible) {
        if (Test-Path $p) { return $p }
    }
    return $null
}

$inkscape = Find-Inkscape
if (-not $inkscape) {
    Write-Host "Inkscape not found in PATH or common locations." -ForegroundColor Yellow
    Write-Host "Please install Inkscape (https://inkscape.org) and ensure 'inkscape' is in your PATH." -ForegroundColor Yellow
    exit 2
}

Write-Host "Using Inkscape at: $inkscape"

# Target sizes for mipmap (pixels)
$sizes = @{
    'mipmap-mdpi' = 48;
    'mipmap-hdpi' = 72;
    'mipmap-xhdpi' = 96;
    'mipmap-xxhdpi' = 144;
    'mipmap-xxxhdpi' = 192;
}

$resRoot = Join-Path $projectRoot 'android\app\src\main\res'

foreach ($kv in $sizes.GetEnumerator()) {
    $folder = Join-Path $resRoot $kv.Key
    if (-not (Test-Path $folder)) { New-Item -ItemType Directory -Path $folder | Out-Null }
    $outFile = Join-Path $folder 'ic_splash_logo.png'

    Write-Host "Exporting $($kv.Key) -> $outFile (size: $($kv.Value)px)"

    # Modern Inkscape CLI: `inkscape input.svg --export-filename=out.png --export-width=W --export-height=H`
    # Use Start-Process with argument array and wait for completion
    $args1 = @($svgPath, "--export-filename=$outFile", "--export-width=$($kv.Value)", "--export-height=$($kv.Value)")
    $proc = Start-Process -FilePath $inkscape -ArgumentList $args1 -NoNewWindow -Wait -PassThru -ErrorAction SilentlyContinue
    if ($proc -and $proc.ExitCode -ne 0) {
        # Fallback with explicit export-type
        $args2 = @($svgPath, "--export-type=png", "--export-filename=$outFile", "--export-width=$($kv.Value)", "--export-height=$($kv.Value)")
        $proc2 = Start-Process -FilePath $inkscape -ArgumentList $args2 -NoNewWindow -Wait -PassThru -ErrorAction SilentlyContinue
        if (-not $proc2 -or $proc2.ExitCode -ne 0) { Write-Warning "Inkscape export failed for $($kv.Key). ExitCode: $($proc2.ExitCode)" }
    }
    if (-not (Test-Path $outFile)) { Write-Warning "Expected output $outFile not found after export." }
}

# Also export copies directly to the same folder as the logo: assets/images
# This keeps splash images colocated with the logo as requested.
$assetSplashDir = Join-Path $projectRoot 'assets\images'
if (-not (Test-Path $assetSplashDir)) { New-Item -ItemType Directory -Path $assetSplashDir | Out-Null }

# Export a reasonable large size for Flutter-level usage and scaled versions for iOS
# Export splash images into assets/images with standard Flutter naming (1x, 2x, 3x)
$iosBase = 400
$iosSizes = @{
    'splash.png' = $iosBase;        # 1x
    'splash@2x.png' = ($iosBase * 2);# 2x
    'splash@3x.png' = ($iosBase * 3);# 3x
}

foreach ($kv in $iosSizes.GetEnumerator()) {
        $outFile = Join-Path $assetSplashDir $kv.Key
        Write-Host "Exporting asset copy -> $outFile (size: $($kv.Value)px)"
        # Use Start-Process to export into assets/images
        $args1 = @($svgPath, "--export-filename=$outFile", "--export-width=$($kv.Value)", "--export-height=$($kv.Value)")
        $proc = Start-Process -FilePath $inkscape -ArgumentList $args1 -NoNewWindow -Wait -PassThru -ErrorAction SilentlyContinue
        if ($proc -and $proc.ExitCode -ne 0) {
            $args2 = @($svgPath, "--export-type=png", "--export-filename=$outFile", "--export-width=$($kv.Value)", "--export-height=$($kv.Value)")
            $proc2 = Start-Process -FilePath $inkscape -ArgumentList $args2 -NoNewWindow -Wait -PassThru -ErrorAction SilentlyContinue
            if (-not $proc2 -or $proc2.ExitCode -ne 0) { Write-Warning "Inkscape export failed for asset copy $($kv.Key). ExitCode: $($proc2.ExitCode)" }
        }
        if (-not (Test-Path $outFile)) { Write-Warning "Expected asset $outFile not found after export." }
}

# Create iOS LaunchImage.imageset using those exported images
$iosSet = Join-Path $projectRoot 'ios\Runner\Assets.xcassets\LaunchImage.imageset'
if (-not (Test-Path $iosSet)) { New-Item -ItemType Directory -Path $iosSet | Out-Null }

foreach ($f in $iosSizes.Keys) {
    $src = Join-Path $assetSplashDir $f
    if (-not (Test-Path $src)) { Write-Warning "Expected asset $src not found, skipping copy to iOS imageset."; continue }
    $dst = Join-Path $iosSet $f
    Copy-Item -Path $src -Destination $dst -Force
}

$contents = @'
{
    "images" : [
        {
            "filename" : "splash.png",
            "idiom" : "universal",
            "scale" : "1x"
        },
        {
            "filename" : "splash@2x.png",
            "idiom" : "universal",
            "scale" : "2x"
        },
        {
            "filename" : "splash@3x.png",
            "idiom" : "universal",
            "scale" : "3x"
        }
    ],
    "info" : {
        "version" : 1,
        "author" : "xcode"
    }
}
'@

Set-Content -Path (Join-Path $iosSet 'Contents.json') -Value $contents -Encoding UTF8
Write-Host "Generated iOS imageset at: $iosSet"

# Update launch_background.xml to reference mipmap ic_splash_logo
$launchXml = Join-Path $resRoot 'drawable\launch_background.xml'
if (-not (Test-Path $launchXml)) {
    Write-Warning "launch_background.xml not found at $launchXml. Skipping XML update.";
} else {
    $content = Get-Content $launchXml -Raw
    # Replace any bitmap src or existing items to point to @mipmap/ic_splash_logo
    $new = @"
<?xml version="1.0" encoding="utf-8"?>
<!-- Launch splash updated to use mipmap ic_splash_logo -->
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@android:color/white" />

    <item>
        <bitmap
            android:gravity="center"
            android:src="@mipmap/ic_splash_logo" />
    </item>
</layer-list>
"@
    Set-Content -Path $launchXml -Value $new -Encoding UTF8
    Write-Host "Updated $launchXml to reference @mipmap/ic_splash_logo"
}

Write-Host "Done. Please rebuild your app (flutter build apk) to include the native splash changes." -ForegroundColor Green
