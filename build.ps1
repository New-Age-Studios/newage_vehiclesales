# Script para gerar uma release limpa do script para FiveM
$ReleaseName = "newage_vehiclesales.zip"

Write-Host "Iniciando criacao do ZIP de Release..." -ForegroundColor Cyan

# Remove o ZIP antigo se existir
if (Test-Path $ReleaseName) {
    Remove-Item $ReleaseName -Force
}

# Arquivos e pastas permitidos na release (Tudo essencial do FiveM, menos web e source files)
$IncludeFiles = @(
    "client",
    "server",
    "shared",
    "html",
    "config",
    "locales",
    "fxmanifest.lua",
    "newage-vehiclesales.sql",
    "README.md",
    "LICENSE"
)

# Cria o arquivo ZIP apenas com os diretórios necessários
Compress-Archive -Path $IncludeFiles -DestinationPath $ReleaseName -Force

Write-Host "ZIP Gerado com sucesso: $ReleaseName" -ForegroundColor Green
Write-Host "Voce pode anexar este arquivo $ReleaseName na pagina de Releases do GitHub!" -ForegroundColor Yellow
Pause
