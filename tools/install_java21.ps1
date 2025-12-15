# Script para instalar Java 21 LTS (versão estável)
param()
$ErrorActionPreference = 'Stop'

Write-Host "===== Installing Java 21 LTS (OpenJDK) =====" -ForegroundColor Cyan

# Java 21 LTS download URL (Windows x64) - usando Adoptium (confiável)
$javaUrl = 'https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.2%2B13/OpenJDK21U-jdk_x64_windows_hotspot_21.0.2_13.zip'
$javaZip = Join-Path $env:TEMP 'java21.zip'

Write-Host "Downloading Java 21 LTS..." -ForegroundColor Yellow
Write-Host "Source: Adoptium (confiável)" -ForegroundColor Cyan

try {
    # Usar redirects automáticos
    Invoke-WebRequest -Uri $javaUrl -OutFile $javaZip -UseBasicParsing -TimeoutSec 300 -MaximumRedirection 5
    Write-Host "Downloaded successfully ($(((Get-Item $javaZip).Length / 1MB) -as [int])MB)" -ForegroundColor Green
} catch {
    Write-Host "Adoptium download failed, trying alternative source..." -ForegroundColor Yellow
    
    # Alternativa: Oracle JDK 21
    $javaUrl2 = 'https://download.oracle.com/java/21/latest/jdk-21_windows-x64_bin.zip'
    try {
        Invoke-WebRequest -Uri $javaUrl2 -OutFile $javaZip -UseBasicParsing -TimeoutSec 300 -MaximumRedirection 5
        Write-Host "Downloaded from Oracle successfully" -ForegroundColor Green
    } catch {
        Write-Host "Both downloads failed. Please download Java 21 manually:" -ForegroundColor Red
        Write-Host "https://www.oracle.com/java/technologies/javase/jdk21-archive-downloads.html" -ForegroundColor Yellow
        exit 1
    }
}

Write-Host "Extracting..." -ForegroundColor Yellow
$javaBaseDir = Join-Path $env:ProgramFiles 'Java'
New-Item -ItemType Directory -Force -Path $javaBaseDir | Out-Null
Expand-Archive -Path $javaZip -DestinationPath $javaBaseDir -Force
Remove-Item $javaZip -Force

# Find the extracted directory
$javaDir = Get-ChildItem -Path $javaBaseDir -Directory -Filter "jdk-*" | Sort-Object -Property Name -Descending | Select-Object -First 1

if (-not $javaDir) {
    # Try without jdk- prefix
    $javaDir = Get-ChildItem -Path $javaBaseDir -Directory | Where-Object { $_.Name -like "*21*" -or $_.Name -like "*java*" } | Select-Object -First 1
}

if ($javaDir) {
    $javaPath = $javaDir.FullName
    Write-Host "Java extracted to: $javaPath" -ForegroundColor Green
    
    # Set JAVA_HOME
    Write-Host "Setting JAVA_HOME..." -ForegroundColor Yellow
    setx JAVA_HOME $javaPath | Out-Null
    $env:JAVA_HOME = $javaPath
    
    # Verify java command
    Write-Host "Verifying Java installation..." -ForegroundColor Yellow
    $javaExe = Join-Path $javaPath 'bin\java.exe'
    if (Test-Path $javaExe) {
        & $javaExe -version
        Write-Host "✅ Java installation verified!" -ForegroundColor Green
    } else {
        Write-Error "Java executable not found at $javaExe"
        exit 1
    }
    
    # Add to PATH
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    if ($userPath -notlike "*$javaPath*") {
        Write-Host "Adding Java to user PATH..." -ForegroundColor Yellow
        $newPath = "$userPath;$javaPath\bin"
        setx Path $newPath | Out-Null
    }
    
    Write-Host "`n✅ Java 21 LTS installed successfully!" -ForegroundColor Green
    Write-Host "JAVA_HOME: $javaPath" -ForegroundColor Green
    
} else {
    Write-Error "Could not find extracted Java directory"
    exit 1
}

Write-Host "`n===== Next Steps =====" -ForegroundColor Cyan
Write-Host "Now run the sdkmanager commands:" -ForegroundColor Yellow
Write-Host @"
`$sdk = "`$env:LOCALAPPDATA\Android\Sdk"
`$mgr = "`$sdk\cmdline-tools\latest\bin\sdkmanager.bat"
& `$mgr "platform-tools" "platforms;android-33" "build-tools;33.0.2"
"@ -ForegroundColor Green
