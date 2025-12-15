# Script para instalar Android cmdline-tools (versão oficial)
# Baixa o pacote cmdline-tools do repositório oficial do Google

param()
$ErrorActionPreference = 'Stop'

$sdk = Join-Path $env:LOCALAPPDATA 'Android\Sdk'
Write-Host "Installing Android cmdline-tools..." -ForegroundColor Cyan
Write-Host "SDK path: $sdk"

# URL do cmdline-tools oficial (windows)
$url = 'https://dl.google.com/android/repository/commandlinetools-win-10406996_latest.zip'
$zipPath = Join-Path $env:TEMP 'cmdline-tools.zip'

Write-Host "`nDownloading cmdline-tools from: $url" -ForegroundColor Yellow
try {
    Invoke-WebRequest -Uri $url -OutFile $zipPath -UseBasicParsing
    Write-Host "Downloaded successfully" -ForegroundColor Green
} catch {
    Write-Host "First URL failed, trying alternative..." -ForegroundColor Yellow
    $url = 'https://dl.google.com/android/repository/commandlinetools-win-9477386_latest.zip'
    try {
        Invoke-WebRequest -Uri $url -OutFile $zipPath -UseBasicParsing
        Write-Host "Downloaded successfully from alternative" -ForegroundColor Green
    } catch {
        Write-Error "Download failed from all sources. Please download manually from: https://developer.android.com/studio#command-line-tools-only"
        exit 1
    }
}

# Create cmdline-tools directory structure
$cmdlineToolsPath = Join-Path $sdk 'cmdline-tools'
$latestPath = Join-Path $cmdlineToolsPath 'latest'
New-Item -ItemType Directory -Force -Path $latestPath | Out-Null

# Extract
Write-Host "Extracting..." -ForegroundColor Yellow
$tempExtract = Join-Path $env:TEMP 'cmdline-extract'
if (Test-Path $tempExtract) { Remove-Item $tempExtract -Recurse -Force }
Expand-Archive -Path $zipPath -DestinationPath $tempExtract -Force

# Move contents to latest directory
$sourceContents = Get-ChildItem -Path (Join-Path $tempExtract 'cmdline-tools') -Force
foreach ($item in $sourceContents) {
    Move-Item -Path $item.FullName -Destination $latestPath -Force
}

Remove-Item $tempExtract -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item $zipPath -Force -ErrorAction SilentlyContinue

# Verify sdkmanager exists
$sdkmanager = Join-Path $latestPath 'bin\sdkmanager.bat'
if (Test-Path $sdkmanager) {
    Write-Host "cmdline-tools installed successfully" -ForegroundColor Green
    Write-Host "sdkmanager location: $sdkmanager" -ForegroundColor Green
    
    # Update PATH if needed
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    if ($userPath -notlike "*cmdline-tools*") {
        Write-Host "Adding cmdline-tools/bin to PATH..."
        $newPath = "$userPath;$latestPath\bin"
        setx Path $newPath | Out-Null
        Write-Host "PATH updated. Restart your terminal to apply changes." -ForegroundColor Yellow
    }
} else {
    Write-Error "sdkmanager not found after extraction"
    exit 1
}

Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "1. Restart PowerShell/VS Code to load environment variables"
Write-Host "2. Run: sdkmanager `"platform-tools`" `"platforms;android-33`" `"build-tools;33.0.2`""
Write-Host "3. Run: sdkmanager --licenses (and accept all licenses)"
Write-Host "4. Run: flutter doctor (to verify setup)"
Write-Host "5. Run: flutter build apk --release"
