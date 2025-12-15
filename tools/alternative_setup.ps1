# Script alternativo: Usar versão compatível com Java 8 ou instalar Android Studio

Write-Host "===== Android SDK Setup (Alternative Path) =====" -ForegroundColor Cyan

$sdk = Join-Path $env:LOCALAPPDATA 'Android\Sdk'
Write-Host "SDK path: $sdk"

Write-Host "`nOpção 1: Instalar Android Studio (recomendado - inclui tudo)" -ForegroundColor Yellow
Write-Host "- Baixe em: https://developer.android.com/studio"
Write-Host "- Instale normalmente"
Write-Host "- Durante a instalação, selecione para instalar Android SDK e ferramentas"
Write-Host "- O Android Studio configura tudo automaticamente"

Write-Host "`nOpção 2: Download manual do cmdline-tools compatível com Java 8" -ForegroundColor Yellow
Write-Host "- URL: https://dl.google.com/android/repository/commandlinetools-win-8512546_latest.zip"
Write-Host "- Extrair em: $sdk\cmdline-tools\latest"
Write-Host "- Depois executar: sdkmanager --licenses"

Write-Host "`nOpção 3: Instalar Java 17 manualmente" -ForegroundColor Yellow
Write-Host "- Visite: https://adoptium.net/temurin/releases/?version=17"
Write-Host "- Baixe o instalador Windows x64 (MSI)"
Write-Host "- Instale normalmente (isso cria as variáveis de ambiente)"
Write-Host "- Depois reinicie PowerShell e tente novamente"

Write-Host "`n⚠️  Recomendação:" -ForegroundColor Cyan
Write-Host "A opção mais simples é instalar Android Studio (Opção 1)"
Write-Host "Isso resolve todos os problemas de dependências de uma vez"
