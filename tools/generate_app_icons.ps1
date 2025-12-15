# Script para gerar icones do app a partir do SVG usando Inkscape

param(
    [string]$svgPath = "assets/images/logo.svg"
)

# Encontrar Inkscape
$inkscapePaths = @(
    "C:\Program Files\Inkscape\bin\inkscape.exe",
    "C:\Program Files (x86)\Inkscape\bin\inkscape.exe",
    "inkscape.exe"
)

$inkscapePath = $null
foreach ($path in $inkscapePaths) {
    if (Test-Path $path) {
        $inkscapePath = $path
        break
    }
}

if (-not $inkscapePath) {
    Write-Host "Erro: Inkscape nao encontrado!" -ForegroundColor Red
    exit 1
}

Write-Host "Inkscape encontrado: $inkscapePath" -ForegroundColor Green

if (-not (Test-Path $svgPath)) {
    Write-Host "Erro: SVG nao encontrado: $svgPath" -ForegroundColor Red
    exit 1
}

Write-Host "SVG encontrado: $svgPath" -ForegroundColor Green

# Criar diretorios Android
$androidDir = "android/app/src/main/res"

@(
    "$androidDir/mipmap-ldpi",
    "$androidDir/mipmap-mdpi",
    "$androidDir/mipmap-hdpi",
    "$androidDir/mipmap-xhdpi",
    "$androidDir/mipmap-xxhdpi",
    "$androidDir/mipmap-xxxhdpi"
) | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item -ItemType Directory -Path $_ -Force | Out-Null
        Write-Host "Diretorio criado: $_" -ForegroundColor Green
    }
}

# Tamanhos Android
$androidSizes = @{
    "ldpi" = 36;
    "mdpi" = 48;
    "hdpi" = 72;
    "xhdpi" = 96;
    "xxhdpi" = 144;
    "xxxhdpi" = 192;
}

Write-Host "Gerando icones Android..." -ForegroundColor Cyan

foreach ($dpi in $androidSizes.Keys) {
    $size = $androidSizes[$dpi]
    $outputPath = "$androidDir/mipmap-$dpi/ic_launcher_foreground.png"
    
    Write-Host "Gerando $dpi (${size}x${size})..." -ForegroundColor Gray
    
    & $inkscapePath --export-type=png -w $size -h $size -o "$outputPath" "$svgPath" 2>$null
    
    if (Test-Path $outputPath) {
        Write-Host "OK: $outputPath" -ForegroundColor Green
    }
}

# Criar diretorio iOS
$iosDir = "ios/Runner/Assets.xcassets/AppIcon.appiconset"
if (-not (Test-Path $iosDir)) {
    New-Item -ItemType Directory -Path $iosDir -Force | Out-Null
    Write-Host "Diretorio iOS criado: $iosDir" -ForegroundColor Green
}

# Tamanhos iOS
$iosSizes = @{
    "AppIcon-20x20@1x" = 20;
    "AppIcon-20x20@2x" = 40;
    "AppIcon-20x20@3x" = 60;
    "AppIcon-29x29@1x" = 29;
    "AppIcon-29x29@2x" = 58;
    "AppIcon-29x29@3x" = 87;
    "AppIcon-40x40@2x" = 80;
    "AppIcon-40x40@3x" = 120;
    "AppIcon-60x60@2x" = 120;
    "AppIcon-60x60@3x" = 180;
    "AppIcon-1024x1024@1x" = 1024;
}

Write-Host "Gerando icones iOS..." -ForegroundColor Cyan

foreach ($name in $iosSizes.Keys) {
    $size = $iosSizes[$name]
    $outputPath = "$iosDir/$name.png"
    
    Write-Host "Gerando $name (${size}x${size})..." -ForegroundColor Gray
    
    & $inkscapePath --export-type=png -w $size -h $size -o "$outputPath" "$svgPath" 2>$null
    
    if (Test-Path $outputPath) {
        Write-Host "OK: $outputPath" -ForegroundColor Green
    }
}

Write-Host "Icones gerados com sucesso!" -ForegroundColor Green
Write-Host "Execute: flutter clean && flutter pub get && flutter build apk --release" -ForegroundColor Cyan
