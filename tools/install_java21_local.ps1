# Script para instalar Java 21 LTS em diretório do usuário (sem Admin)
param()
$ErrorActionPreference = 'Stop'

Write-Host "===== Installing Java 21 LTS =====" -ForegroundColor Cyan

# Java 21 LTS URL (Adoptium)
$javaUrl = 'https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.2%2B13/OpenJDK21U-jdk_x64_windows_hotspot_21.0.2_13.zip'
$javaZip = Join-Path $env:TEMP 'java21.zip'

Write-Host "Downloading Java 21 LTS (195MB)..." -ForegroundColor Yellow

try {
    Invoke-WebRequest -Uri $javaUrl -OutFile $javaZip -UseBasicParsing -TimeoutSec 300 -MaximumRedirection 5
    Write-Host "Downloaded successfully" -ForegroundColor Green
} catch {
    Write-Host "Download failed: $_" -ForegroundColor Red
    exit 1
}

# Instalar em %LOCALAPPDATA% (sem need de Admin)
$javaBaseDir = Join-Path $env:LOCALAPPDATA 'Java'
Write-Host "Extracting to: $javaBaseDir" -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path $javaBaseDir | Out-Null

# Extract
try {
    Expand-Archive -Path $javaZip -DestinationPath $javaBaseDir -Force
    Write-Host "Extracted successfully" -ForegroundColor Green
} catch {
    Write-Host "Extraction failed: $_" -ForegroundColor Red
    exit 1
}

Remove-Item $javaZip -Force -ErrorAction SilentlyContinue

# Find Java directory
$javaDir = Get-ChildItem -Path $javaBaseDir -Directory | Where-Object { $_.Name -like "*jdk*" -or $_.Name -like "*21*" } | Select-Object -First 1

if ($javaDir) {
    $javaPath = $javaDir.FullName
    Write-Host "Java installed to: $javaPath" -ForegroundColor Green
    
    # Set JAVA_HOME
    Write-Host "Setting JAVA_HOME..." -ForegroundColor Yellow
    setx JAVA_HOME $javaPath | Out-Null
    $env:JAVA_HOME = $javaPath
    
    # Add to PATH
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    if ($userPath -notlike "*Java*") {
        Write-Host "Adding Java to user PATH..." -ForegroundColor Yellow
        $newPath = "$userPath;$javaPath\bin"
        setx Path $newPath | Out-Null
    }
    
    # Verify
    Write-Host "Verifying Java..." -ForegroundColor Yellow
    $javaExe = Join-Path $javaPath 'bin\java.exe'
    if (Test-Path $javaExe) {
        & $javaExe -version 2>&1
        Write-Host "✅ Java 21 LTS installed successfully!" -ForegroundColor Green
    } else {
        Write-Error "Java executable not found"
        exit 1
    }
    
} else {
    Write-Error "Could not find Java directory"
    exit 1
}

Write-Host "`n===== Ready to continue =====" -ForegroundColor Green
Write-Host "Environment variables set. Restart PowerShell if needed." -ForegroundColor Yellow
Write-Host "Next, install Android SDK packages using sdkmanager" -ForegroundColor Cyan
