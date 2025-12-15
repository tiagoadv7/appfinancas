# Script para instalar Java 25 (oficial OpenJDK)
param()
$ErrorActionPreference = 'Stop'

Write-Host "===== Installing Java 25 (OpenJDK) =====" -ForegroundColor Cyan

# Java 25 download URL (Windows x64)
$javaUrl = 'https://download.java.net/java/GA/jdk25/850676a6d3cc4e27aa11b36b235731ba/12/GPL/openjdk-25_windows-x64_bin.zip'
$javaZip = Join-Path $env:TEMP 'java25.zip'

Write-Host "Downloading Java 25 from official source..." -ForegroundColor Yellow
Write-Host "URL: $javaUrl"

try {
    Invoke-WebRequest -Uri $javaUrl -OutFile $javaZip -UseBasicParsing -TimeoutSec 300
    Write-Host "Downloaded successfully" -ForegroundColor Green
} catch {
    Write-Host "Download failed: $_" -ForegroundColor Red
    exit 1
}

Write-Host "Extracting to Program Files..." -ForegroundColor Yellow
$javaBaseDir = Join-Path $env:ProgramFiles 'Java'
New-Item -ItemType Directory -Force -Path $javaBaseDir | Out-Null

# Extract directly to Java folder
Expand-Archive -Path $javaZip -DestinationPath $javaBaseDir -Force
Remove-Item $javaZip -Force

# Find the extracted directory (should be jdk-25 or jdk-25.0.0)
$javaDir = Get-ChildItem -Path $javaBaseDir -Directory -Filter "jdk-*" | Sort-Object -Property Name -Descending | Select-Object -First 1

if ($javaDir) {
    $javaPath = $javaDir.FullName
    Write-Host "Java 25 installed to: $javaPath" -ForegroundColor Green
    
    # Set JAVA_HOME environment variable
    Write-Host "Setting JAVA_HOME environment variable..." -ForegroundColor Yellow
    setx JAVA_HOME $javaPath | Out-Null
    
    # Add to PATH if not already there
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    if ($userPath -notlike "*$javaPath*") {
        Write-Host "Adding Java bin directory to user PATH..." -ForegroundColor Yellow
        $newPath = "$userPath;$javaPath\bin"
        setx Path $newPath | Out-Null
    } else {
        Write-Host "Java bin directory already in PATH" -ForegroundColor Green
    }
    
    Write-Host "`n✅ Java 25 installed successfully!" -ForegroundColor Green
    Write-Host "JAVA_HOME: $javaPath" -ForegroundColor Green
    Write-Host "`n⚠️  ACTION REQUIRED: Restart PowerShell/VS Code to load the new Java environment" -ForegroundColor Yellow
    Write-Host "After restarting, run these commands:" -ForegroundColor Cyan
    Write-Host @"
  cd "C:\Users\Tiago Neves\Documents\GitHub\appfinancas"
  `$sdk = "`$env:LOCALAPPDATA\Android\Sdk"
  `$mgr = "`$sdk\cmdline-tools\latest\bin\sdkmanager.bat"
  & `$mgr "platform-tools" "platforms;android-33" "build-tools;33.0.2"
  & `$mgr --licenses
  flutter config --android-sdk "`$sdk"
  flutter doctor
  flutter build apk --release
"@ -ForegroundColor Green
    
} else {
    Write-Error "Could not find extracted Java directory in $javaBaseDir"
    exit 1
}
