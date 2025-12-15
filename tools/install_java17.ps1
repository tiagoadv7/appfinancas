# Script para instalar Java 17 LTS
param()
$ErrorActionPreference = 'Stop'

Write-Host "Downloading Java 17 LTS (OpenJDK)..." -ForegroundColor Cyan
$javaZip = Join-Path $env:TEMP 'java17.zip'
$javaUrl = 'https://download.java.net/java/GA/jdk17.0.7/886e53c456c24be59b7cba4dd3d28ff36ef88e6b/jdk-17.0.7_windows-x64_bin.zip'

try {
    Invoke-WebRequest -Uri $javaUrl -OutFile $javaZip -UseBasicParsing
    Write-Host "Downloaded successfully" -ForegroundColor Green
} catch {
    Write-Error "Java download failed. Please install Java 17+ manually from: https://www.oracle.com/java/technologies/javase/jdk17-archive-downloads.html"
    exit 1
}

Write-Host "Extracting..." -ForegroundColor Yellow
$javaBaseDir = Join-Path $env:ProgramFiles 'Java'
New-Item -ItemType Directory -Force -Path $javaBaseDir | Out-Null
Expand-Archive -Path $javaZip -DestinationPath $javaBaseDir -Force
Remove-Item $javaZip -Force

# Find extracted JDK directory
$javaDir = Get-ChildItem -Path $javaBaseDir -Directory -Filter "jdk-*" | Select-Object -First 1
if ($javaDir) {
    $javaPath = $javaDir.FullName
    Write-Host "Java installed to: $javaPath" -ForegroundColor Green
    
    # Set environment variables
    Write-Host "Setting JAVA_HOME..." -ForegroundColor Yellow
    setx JAVA_HOME $javaPath | Out-Null
    
    # Update PATH
    $oldPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    if ($oldPath -notlike "*$javaPath*") {
        setx Path "$oldPath;$javaPath\bin" | Out-Null
    }
    
    Write-Host "Java 17 installed successfully!" -ForegroundColor Green
    Write-Host "JAVA_HOME: $javaPath" -ForegroundColor Green
    Write-Host "`nRestart PowerShell to apply environment changes." -ForegroundColor Yellow
} else {
    Write-Error "Could not find extracted Java directory"
    exit 1
}
