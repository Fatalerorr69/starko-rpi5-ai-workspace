Write-Host "=============================================" -ForegroundColor Magenta
Write-Host "   STARKO WORKSPACE - WINDOWS INSTALÁTOR"
Write-Host "=============================================" -ForegroundColor Magenta

# Proměnné
$StarkoProfile = "$env:USERPROFILE\StarkoMasterProfile"
$VSCodePath = "$env:APPDATA\Code\User"
$BackupDir = "$StarkoProfile\backups"
$InstallLog = "$StarkoProfile\install.log"

# Funkce pro logování
function Log {
    param([string]$Message, [string]$Color = "White")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$Timestamp] $Message" -ForegroundColor $Color
    Add-Content -Path $InstallLog -Value "[$Timestamp] $Message"
}

function LogSuccess {
    param([string]$Message)
    Log "✅ $Message" "Green"
}

function LogError {
    param([string]$Message)
    Log "❌ $Message" "Red"
}

function LogWarning {
    param([string]$Message)
    Log "⚠️  $Message" "Yellow"
}

function LogStep {
    param([string]$Message)
    Log "🎯 $Message" "Blue"
}

# Kontrola závislostí
function CheckDependencies {
    LogStep "Kontrola závislostí..."
    
    $missing = @()
    
    # Kontrola Python
    if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
        $missing += "Python"
    }
    
    # Kontrola VS Code
    if (-not (Get-Command code -ErrorAction SilentlyContinue)) {
        LogWarning "VS Code není v PATH. Některé funkce nemusí fungovat."
    }
    
    if ($missing.Count -gt 0) {
        LogError "Chybějící závislosti: $($missing -join ', ')"
        Log "Pokus o instalaci chybějících závislostí..."
        
        # Pokus o instalaci Python pomocí winget
        if ($missing -contains "Python") {
            try {
                winget install Python.Python.3.11
                LogSuccess "Python úspěšně nainstalován"
            } catch {
                LogError "Nelze nainstalovat Python. Instalujte ručně z python.org"
                return $false
            }
        }
    }
    
    LogSuccess "Všechny závislosti jsou nainstalovány"
    return $true
}

# Vytvoření adresářů
function CreateDirectories {
    LogStep "Vytváření adresářů..."
    
    New-Item -ItemType Directory -Path $StarkoProfile -Force | Out-Null
    New-Item -ItemType Directory -Path "$VSCodePath\snippets" -Force | Out-Null
    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
    New-Item -ItemType Directory -Path "$StarkoProfile\themes" -Force | Out-Null
    New-Item -ItemType Directory -Path "$StarkoProfile\icons" -Force | Out-Null
    
    LogSuccess "Adresáře vytvořeny"
}

# Záloha existující konfigurace
function BackupExistingConfig {
    LogStep "Zálohování existující konfigurace..."
    
    $Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $BackupPath = "$BackupDir\$Timestamp"
    
    New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null
    
    if (Test-Path $VSCodePath) {
        if (Test-Path "$VSCodePath\settings.json") {
            Copy-Item "$VSCodePath\settings.json" "$BackupPath\" -Force
        }
        if (Test-Path "$VSCodePath\extensions.json") {
            Copy-Item "$VSCodePath\extensions.json" "$BackupPath\" -Force
        }
        if (Test-Path "$VSCodePath\tasks.json") {
            Copy-Item "$VSCodePath\tasks.json" "$BackupPath\" -Force
        }
        if (Test-Path "$VSCodePath\launch.json") {
            Copy-Item "$VSCodePath\launch.json" "$BackupPath\" -Force
        }
        if (Test-Path "$VSCodePath\snippets") {
            Copy-Item "$VSCodePath\snippets\*" "$BackupPath\snippets\" -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    
    LogSuccess "Záloha vytvořena: $BackupPath"
}

# Instalace tématu
function InstallTheme {
    LogStep "Instalace Starko Dark Pro tématu..."
    
    try {
        Copy-Item "..\..\themes\starko-dark-pro.json" "$VSCodePath\" -Force
        LogSuccess "Téma instalováno"
        return $true
    } catch {
        LogError "Chyba při instalaci tématu: $_"
        return $false
    }
}

# Instalace snippetů
function InstallSnippets {
    LogStep "Instalace snippetů..."
    
    try {
        Copy-Item "..\..\snippets\*.json" "$VSCodePath\snippets\" -Force
        LogSuccess "Snippety instalovány"
        return $true
    } catch {
        LogError "Chyba při instalaci snippetů: $_"
        return $false
    }
}

# Instalace konfigurace VS Code
function InstallVSCodeConfig {
    LogStep "Instalace VS Code konfigurace..."
    
    try {
        Copy-Item "..\..\.vscode\*.json" "$VSCodePath\" -Force
        LogSuccess "Konfigurace VS Code instalována"
        return $true
    } catch {
        LogError "Chyba při instalaci konfigurace: $_"
        return $false
    }
}

# Instalace ikon
function InstallIcons {
    LogStep "Instalace ikon..."
    
    try {
        if (Test-Path "..\..\icons") {
            Copy-Item "..\..\icons\*" "$StarkoProfile\icons\" -Recurse -Force -ErrorAction SilentlyContinue
        }
        LogSuccess "Ikony instalovány"
        return $true
    } catch {
        LogWarning "Chyba při instalaci ikon: $_"
        return $false
    }
}

# Ověření instalace
function VerifyInstallation {
    LogStep "Kontrola instalace..."
    
    $errors = 0
    $requiredFiles = @(
        "$VSCodePath\settings.json",
        "$VSCodePath\starko-dark-pro.json",
        "$VSCodePath\snippets\python.json",
        "$VSCodePath\snippets\bash.json"
    )
    
    foreach ($file in $requiredFiles) {
        if (-not (Test-Path $file)) {
            LogError "Chybí soubor: $file"
            $errors++
        }
    }
    
    if ($errors -eq 0) {
        LogSuccess "Instalace úspěšně ověřena"
        return $true
    } else {
        LogError "Instalace obsahuje chyby: $errors chybějících souborů"
        return $false
    }
}

# Oprava instalace
function FixInstallation {
    LogStep "Oprava instalace..."
    
    InstallTheme
    InstallSnippets
    InstallVSCodeConfig
    InstallIcons
    
    LogSuccess "Oprava dokončena"
}

# Hlavní instalační funkce
function MainInstallation {
    # Vytvoření log souboru
    New-Item -ItemType Directory -Path $StarkoProfile -Force | Out-Null
    if (Test-Path $InstallLog) {
        Remove-Item $InstallLog -Force
    }
    New-Item -ItemType File -Path $InstallLog -Force | Out-Null
    
    Log "Spouštím instalaci Starko Workspace..."
    
    # Hlavní instalace
    if (-not (CheckDependencies)) {
        LogError "Instalace závislostí selhala"
        exit 1
    }
    
    CreateDirectories
    BackupExistingConfig
    InstallTheme
    InstallSnippets
    InstallVSCodeConfig
    InstallIcons
    
    # Ověření
    if (VerifyInstallation) {
        Write-Host ""
        Write-Host "=============================================" -ForegroundColor Green
        Write-Host "       WINDOWS INSTALACE DOKONČENA!"
        Write-Host "=============================================" -ForegroundColor Green
        Write-Host ""
        
        LogSuccess "Starko Workspace byl úspěšně nainstalován"
        Write-Host ""
        Write-Host "Následující kroky:" -ForegroundColor Cyan
        Write-Host "1. Restartujte VS Code"
        Write-Host "2. Vyberte téma: Starko Dark Pro"
        Write-Host "3. Nainstalujte doporučená rozšíření"
        Write-Host "4. Spusťte Web GUI: python web_gui/app.py" -ForegroundColor Green
        Write-Host ""
        Write-Host "Instalační log: $InstallLog" -ForegroundColor Yellow
    } else {
        Write-Host ""
        LogError "Instalace obsahuje chyby. Pokus o opravu..."
        FixInstallation
        
        if (VerifyInstallation) {
            LogSuccess "Oprava byla úspěšná"
        } else {
            LogError "Instalace selhala. Zkontrolujte log: $InstallLog"
            exit 1
        fi
    }
}

# Zpracování argumentů
if ($args.Count -gt 0) {
    switch ($args[0]) {
        "--fix" {
            FixInstallation
        }
        "--verify" {
            VerifyInstallation
        }
        "--help" {
            Write-Host "Usage: .\install_starko_windows.ps1 [OPTIONS]"
            Write-Host ""
            Write-Host "Starko Workspace Windows Installer"
            Write-Host ""
            Write-Host "Options:"
            Write-Host "  --fix          Opravit instalaci"
            Write-Host "  --verify       Ověřit instalaci"
            Write-Host "  --help         Zobrazit nápovědu"
            Write-Host ""
            Write-Host "Examples:"
            Write-Host "  .\install_starko_windows.ps1             # Kompletní instalace"
            Write-Host "  .\install_starko_windows.ps1 --fix       # Oprava instalace"
            Write-Host "  .\install_starko_windows.ps1 --verify    # Ověření instalace"
        }
        default {
            MainInstallation
        }
    }
} else {
    MainInstallation
}
