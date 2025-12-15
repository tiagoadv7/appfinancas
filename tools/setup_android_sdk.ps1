# Script de Instalação Android SDK (Platform-Tools Oficial)
# Este script baixa platform-tools do link oficial do Google, configura variáveis
# de ambiente e prepara o Flutter para build APK.

param()

$ErrorActionPreference = 'Stop'

# Definir caminho do SDK
$sdk = Join-Path $env:LOCALAPPDATA 'Android\Sdk'
Write-Host "===== Android SDK Setup =====" -ForegroundColor Cyan
Write-Host "SDK path: $sdk"

# Criar diretórios
New-Item -ItemType Directory -Force -Path $sdk | Out-Null
New-Item -ItemType Directory -Force -Path "$sdk\platform-tools" | Out-Null

# Download platform-tools (Windows x64) do link oficial
$zipPath = Join-Path $env:TEMP 'platform-tools.zip'
$url = 'https://dl.google.com/android/repository/platform-tools-latest-windows.zip'

Write-Host "`nDownloading platform-tools from official Google source..." -ForegroundColor Yellow
Write-Host "URL: $url"
try {
    Invoke-WebRequest -Uri $url -OutFile $zipPath -UseBasicParsing
    Write-Host "Downloaded successfully to: $zipPath" -ForegroundColor Green
} catch {
    Write-Host "Download failed: $_" -ForegroundColor Red
    exit 1
}

# Extrair
Write-Host "Extracting platform-tools..." -ForegroundColor Yellow
$tempExtract = Join-Path $env:TEMP 'pt-extract'
if (Test-Path $tempExtract) { Remove-Item $tempExtract -Recurse -Force }
Expand-Archive -Path $zipPath -DestinationPath $tempExtract -Force

# Mover para o local correto
Write-Host "Installing to: $sdk\platform-tools"
Get-ChildItem -Path "$tempExtract\platform-tools" -Force | Move-Item -Destination "$sdk\platform-tools" -Force
Remove-Item $tempExtract -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item $zipPath -Force -ErrorAction SilentlyContinue

# Configurar variáveis de ambiente
Write-Host "`nConfiguring user environment variables..." -ForegroundColor Yellow
setx ANDROID_SDK_ROOT $sdk | Out-Null
setx ANDROID_HOME $sdk | Out-Null

# Adicionar ao PATH (apenas se não estiver lá)
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if ($userPath -notlike "*platform-tools*") {
    Write-Host "Adding platform-tools to user PATH..."
    $newPath = "$userPath;$sdk\platform-tools"
    setx Path $newPath | Out-Null
} else {
    Write-Host "platform-tools already in PATH"
}

Write-Host "`n===== Environment Setup Complete =====" -ForegroundColor Green
Write-Host "ANDROID_SDK_ROOT = $sdk" -ForegroundColor Green
Write-Host "ANDROID_HOME = $sdk" -ForegroundColor Green
Write-Host "platform-tools location: $sdk\platform-tools" -ForegroundColor Green

Write-Host "`n⚠️  IMPORTANT: Please restart PowerShell/VS Code to load the new environment variables." -ForegroundColor Yellow
Write-Host "After restart, run the following commands to complete setup:" -ForegroundColor Cyan
Write-Host @"
  flutter config --android-sdk '$sdk'
  flutter doctor
  flutter build apk --release
"@ -ForegroundColor Cyan

Write-Host "`nSetup script completed successfully!" -ForegroundColor Green
