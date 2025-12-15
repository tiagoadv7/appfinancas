param()
$ErrorActionPreference = 'Stop'

$sdk = Join-Path $env:LOCALAPPDATA 'Android\Sdk'
Write-Host "Android SDK path: $sdk"

# Create SDK dir
New-Item -ItemType Directory -Force -Path $sdk | Out-Null

# Download command-line tools
$zip = Join-Path $env:TEMP 'cmdline-tools.zip'
Write-Host "Downloading command-line tools to: $zip (may take some minutes)..."
Invoke-WebRequest -Uri 'https://dl.google.com/android/repository/commandlinetools-win-latest.zip' -OutFile $zip -UseBasicParsing
Write-Host 'Download complete.'

# Extract
$dest = Join-Path $sdk 'cmdline-tools-temp'
if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }
Write-Host 'Extracting...'
Expand-Archive -Path $zip -DestinationPath $dest -Force

# Move extracted files into cmdline-tools/latest
$targetLatest = Join-Path $sdk 'cmdline-tools\latest'
New-Item -ItemType Directory -Force -Path $targetLatest | Out-Null
if (Test-Path (Join-Path $dest 'cmdline-tools')) {
  Get-ChildItem -Path (Join-Path $dest 'cmdline-tools') -Force | Move-Item -Destination $targetLatest -Force
} else {
  Get-ChildItem -Path $dest -Force | Move-Item -Destination $targetLatest -Force
}

# Clean up temp
Remove-Item $dest -Recurse -Force -ErrorAction SilentlyContinue

# Set user environment variables
Write-Host 'Setting user environment variables ANDROID_SDK_ROOT and ANDROID_HOME'
setx ANDROID_SDK_ROOT $sdk | Out-Null
setx ANDROID_HOME $sdk | Out-Null

# Append platform-tools and cmdline-tools to user PATH (if not present)
$oldPath = [Environment]::GetEnvironmentVariable('Path','User')
$newEntries = "$sdk\platform-tools;$sdk\cmdline-tools\latest\bin"
if ($oldPath -notlike "*${sdk}*") {
  Write-Host 'Updating user PATH...'
  setx Path ("$oldPath;$newEntries") | Out-Null
} else {
  Write-Host 'User PATH already contains SDK path.'
}

# Install packages using sdkmanager
$mgr = Join-Path $targetLatest 'bin\sdkmanager.bat'
if (!(Test-Path $mgr)) {
  Write-Error "sdkmanager not found at $mgr"
  exit 1
}

Write-Host 'Installing platform-tools, platforms;android-33 and build-tools;33.0.2'
& $mgr "platform-tools" "platforms;android-33" "build-tools;33.0.2"

# Accept licenses (pipe many 'y' answers)
Write-Host 'Accepting SDK licenses...'
$confirm = (1..60 | ForEach-Object { 'y' }) -join "`n"
$confirm | & $mgr --licenses

# Inform Flutter about SDK path and run doctor
Write-Host 'Configuring Flutter to use the Android SDK...'
flutter config --android-sdk $sdk

Write-Host 'Running flutter doctor...'
flutter doctor

# Build APK
Write-Host 'Building APK (release) - this may take several minutes...'
flutter build apk --release

Write-Host 'Finished. If successful, APK will be in build\\app\\outputs\\flutter-apk\\'
