#!/bin/bash

# =============================================
# STARKO RPI5 AI WORKSPACE - ROZŠÍŘENÁ VERZE 3.0
# =============================================

# Barvy pro výstup
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Funkce pro logování
log_info() {
    echo -e "${BLUE}ℹ️  INFO:${NC} $1"
}

log_success() {
    echo -e "${GREEN}✅ ÚSPĚCH:${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠️  VAROVÁNÍ:${NC} $1"
}

log_error() {
    echo -e "${RED}❌ CHYBA:${NC} $1"
}

log_debug() {
    echo -e "${PURPLE}🐛 DEBUG:${NC} $1"
}

log_step() {
    echo -e "${CYAN}🎯 KROK:${NC} $1"
}

# Proměnné
WORKSPACE_NAME="starko-rpi5-ai-workspace"
OVERWRITE=false
VENV_NAME="venv"
PYTHON_CMD="python3"
CREATE_VENV=true
INSTALL_DEPS=true
INSTALL_TYPE="auto"

# Funkce pro zobrazení nápovědy
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Generátor kompletního Starko RPi5 AI Workspace"
    echo ""
    echo "Options:"
    echo "  -n, --name NAME      Název workspace (default: starko-rpi5-ai-workspace)"
    echo "  -o, --overwrite      Přepsat existující workspace"
    echo "  --no-venv            Nevytvářet virtuální prostředí"
    echo "  --no-deps            Neinstalovat závislosti"
    echo "  --install-type TYPE  Typ instalace: auto, linux, windows"
    echo "  -h, --help           Zobrazit nápovědu"
    echo ""
    echo "Příklady:"
    echo "  $0                           # Vytvoří výchozí workspace"
    echo "  $0 -n muj-projekt           # Vlastní název"
    echo "  $0 --overwrite              # Přepíše existující"
    echo "  $0 --install-type linux     # Linux specifická instalace"
}

# Zpracování argumentů
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--name)
            WORKSPACE_NAME="$2"
            shift 2
            ;;
        -o|--overwrite)
            OVERWRITE=true
            shift
            ;;
        --no-venv)
            CREATE_VENV=false
            shift
            ;;
        --no-deps)
            INSTALL_DEPS=false
            shift
            ;;
        --install-type)
            INSTALL_TYPE="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            log_error "Neznámý argument: $1"
            show_help
            exit 1
            ;;
    esac
done

# Funkce pro detekci OS
detect_os() {
    case "$(uname -s)" in
        Linux*)     echo "linux";;
        Darwin*)    echo "macos";;
        CYGWIN*)    echo "windows";;
        MINGW*)     echo "windows";;
        *)          echo "unknown";;
    esac
}

# Funkce pro kontrolu závislostí
check_dependencies() {
    log_step "Kontrola závislostí..."
    
    local missing_deps=()
    
    # Kontrola Python
    if ! command -v $PYTHON_CMD &> /dev/null; then
        missing_deps+=("Python3")
    fi
    
    # Kontrola pip
    if ! command -v pip3 &> /dev/null; then
        missing_deps+=("pip3")
    fi
    
    # Kontrola git
    if ! command -v git &> /dev/null; then
        log_warning "Git není nainstalován - některé funkce nebudou dostupné"
    fi
    
    # Kontrola VS Code (volitelné)
    if ! command -v code &> /dev/null; then
        log_warning "VS Code není v PATH - ručně otevřete workspace"
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_error "Chybějící závislosti: ${missing_deps[*]}"
        exit 1
    fi
    
    log_success "Všechny závislosti jsou nainstalovány"
}

# Funkce pro kontrolu existence workspace
check_existing_workspace() {
    local base_dir="$1"
    
    if [ -d "$base_dir" ]; then
        if [ "$OVERWRITE" = true ]; then
            log_warning "Přepisuji existující workspace: $base_dir"
            if ! rm -rf "$base_dir"; then
                log_error "Nelze smazat existující workspace"
                exit 1
            fi
        else
            log_error "Workspace již existuje: $base_dir"
            log_info "Použijte --overwrite pro přepsání"
            exit 1
        fi
    fi
}

# Funkce pro vytvoření adresářové struktury
create_directory_structure() {
    log_step "Vytvářím adresářovou strukturu..."
    
    local base_dir="$1"
    
    # Hlavní adresáře
    declare -a directories=(
        "$base_dir/.vscode"
        "$base_dir/themes"
        "$base_dir/icons"
        "$base_dir/snippets"
        "$base_dir/ai_engine/models"
        "$base_dir/ai_engine/memory" 
        "$base_dir/projects/template"
        "$base_dir/projects/ai_templates"
        "$base_dir/github/actions"
        "$base_dir/scripts/linux"
        "$base_dir/scripts/windows"
        "$base_dir/config"
        "$base_dir/tests"
        "$base_dir/docs"
        "$base_dir/logs"
        "$base_dir/backups"
        "$base_dir/web_gui/templates"
        "$base_dir/web_gui/static/css"
        "$base_dir/web_gui/static/js"
        "$base_dir/web_gui/static/images"
        "$base_dir/web_gui/projects"
        "$base_dir/web_gui/modules"
        "$base_dir/web_gui/logs"
        "$base_dir/installers/linux"
        "$base_dir/installers/windows"
        "$base_dir/system/monitoring"
        "$base_dir/system/backup"
        "$base_dir/system/security"
    )
    
    for dir in "${directories[@]}"; do
        if mkdir -p "$dir"; then
            log_debug "Vytvořen adresář: $dir"
        else
            log_error "Nelze vytvořit adresář: $dir"
            exit 1
        fi
    done
    
    log_success "Adresářová struktura vytvořena"
}

# Funkce pro vytvoření Starko tématu a konfigurace
create_starko_theme() {
    log_step "Vytvářím Starko Dark Pro téma a konfiguraci..."
    
    local base_dir="$1"
    
    # Starko Dark Pro téma
    cat > "$base_dir/themes/starko-dark-pro.json" << 'EOF'
{
  "$schema": "vscode://schemas/color-theme",
  "name": "Starko Dark Pro",
  "type": "dark",
  "colors": {
    "editor.background": "#0D0F14",
    "editor.foreground": "#E4E8EF",

    "editorCursor.foreground": "#6F9CF4",
    "editor.selectionBackground": "#25324A",
    "editor.inactiveSelectionBackground": "#1b2433",
    "editor.lineHighlightBackground": "#1A1D22",

    "editorLineNumber.foreground": "#4C566A",
    "editorLineNumber.activeForeground": "#8FBCBB",

    "activityBar.background": "#11131A",
    "activityBar.foreground": "#E4E8EF",
    "activityBar.activeBorder": "#6F9CF4",

    "sideBar.background": "#13151D",
    "sideBarTitle.foreground": "#AAB2C0",

    "statusBar.background": "#0F1117",
    "statusBar.foreground": "#C9D1D9",

    "tab.activeBackground": "#1C2027",
    "tab.inactiveBackground": "#11131A",
    "tab.activeForeground": "#E4E8EF",
    "tab.inactiveForeground": "#6A707A",

    "terminal.background": "#0D0F14",
    "terminal.foreground": "#C9D1D9",

    "button.background": "#1B3A75",
    "button.foreground": "#FFFFFF",
    "button.hoverBackground": "#274B97"
  },

  "tokenColors": [
    {
      "scope": "comment",
      "settings": {
        "foreground": "#5C6773",
        "fontStyle": "italic"
      }
    },
    {
      "scope": "keyword",
      "settings": {
        "foreground": "#6F9CF4"
      }
    },
    {
      "scope": "string",
      "settings": {
        "foreground": "#8FCE6C"
      }
    },
    {
      "scope": "variable",
      "settings": {
        "foreground": "#E4E8EF"
      }
    },
    {
      "scope": "constant.numeric",
      "settings": {
        "foreground": "#D89CFF"
      }
    },
    {
      "scope": "entity.name.function",
      "settings": {
        "foreground": "#4FC1FF"
      }
    }
  ]
}
EOF

    # Hlavní VS Code konfigurace
    cat > "$base_dir/.vscode/settings.json" << 'EOF'
{
    "workbench.colorTheme": "Starko Dark Pro",
    "workbench.iconTheme": "starko-icons",
    "workbench.productIconTheme": "StarkoIcons",
    
    "workbench.colorCustomizations": {
        "activityBar.background": "#11131A",
        "activityBar.foreground": "#E4E8EF",
        "statusBar.background": "#0F1117"
    },
    
    "editor.fontFamily": "'Cascadia Code', 'Fira Code', Consolas, 'Courier New', monospace",
    "editor.fontSize": 14,
    "editor.lineHeight": 1.5,
    "editor.fontLigatures": true,
    
    "files.autoSave": "afterDelay",
    "files.autoSaveDelay": 1000,
    
    "python.defaultInterpreterPath": "${workspaceFolder}/venv/bin/python",
    "python.analysis.autoImportCompletions": true,
    "python.analysis.typeCheckingMode": "basic",
    
    "terminal.integrated.shell.linux": "/bin/bash",
    "terminal.integrated.fontFamily": "'Cascadia Code'",
    
    "rpi.autoDeploy": true,
    "rpi.simulationMode": true
}
EOF

    # Snippets pro Python
    cat > "$base_dir/snippets/python.json" << 'EOF'
{
    "Python Header": {
        "prefix": "pyheader",
        "body": [
            "#!/usr/bin/env python3",
            "# -*- coding: utf-8 -*-",
            "",
            "\"\"\"",
            "${1:Description}",
            "",
            "Author: ${2:Starko Master}",
            "Created: ${CURRENT_YEAR}-${CURRENT_MONTH}-${CURRENT_DATE}",
            "Version: 1.0.0",
            "\"\"\"",
            "",
            "import sys",
            "import os",
            "from pathlib import Path",
            "",
            "def main():",
            "    \"\"\"Hlavní funkce\"\"\"",
            "    print(\"🚀 Hello from Starko!\")",
            "",
            "if __name__ == \"__main__\":",
            "    main()"
        ],
        "description": "Python script header with Starko style"
    }
}
EOF

    # Snippets pro Bash
    cat > "$base_dir/snippets/bash.json" << 'EOF'
{
    "Bash Header": {
        "prefix": "shheader",
        "body": [
            "#!/bin/bash",
            "",
            "# =============================================",
            "# ${1:Script Name}",
            "# STARKO MASTER - ${CURRENT_YEAR}",
            "# =============================================",
            "",
            "# Colors",
            "RED='\\033[0;31m'",
            "GREEN='\\033[0;32m'",
            "YELLOW='\\033[1;33m'",
            "BLUE='\\033[0;34m'",
            "NC='\\033[0m'",
            "",
            "log_info() {",
            "    echo -e \"\\${BLUE}ℹ️  INFO:\\${NC} $1\"",
            "}",
            "",
            "log_success() {",
            "    echo -e \"\\${GREEN}✅ ÚSPĚCH:\\${NC} $1\"",
            "}",
            "",
            "main() {",
            "    log_info \"Starting script...\"",
            "    # Main code here",
            "    log_success \"Script completed successfully\"",
            "}",
            "",
            "main \"$@\""
        ],
        "description": "Bash script template with Starko style"
    }
}
EOF

    # Vytvoření ikonového tématu
    cat > "$base_dir/icons/starko-icons.json" << 'EOF'
{
    "iconDefinitions": {
        "_starko_folder": {
            "iconPath": "./images/starko-folder.png"
        },
        "_starko_file": {
            "iconPath": "./images/starko-file.png"
        }
    },
    "folder": "_starko_folder",
    "file": "_starko_file"
}
EOF

    log_success "Starko téma a konfigurace vytvořeny"
}

# Funkce pro vytvoření VS Code konfigurace
create_vscode_config() {
    log_step "Vytvářím rozšířenou VS Code konfiguraci..."
    
    local base_dir="$1"
    
    # extensions.json
    cat > "$base_dir/.vscode/extensions.json" << 'EOF'
{
    "recommendations": [
        "ms-python.python",
        "ms-python.vscode-pylance",
        "ms-python.black-formatter",
        
        "GitHub.copilot",
        "GitHub.copilot-chat",
        "codeium.codeium",
        "tabnine.tabnine-vscode",
        
        "ms-vscode.remote-ssh",
        "ms-vscode.remote-ssh-edit",
        "ms-vscode.makefile-tools",
        
        "bradlc.vscode-tailwindcss",
        "ms-vscode.live-server",
        
        "eamodio.gitlens",
        "mhutchie.git-graph",
        
        "ms-azuretools.vscode-docker",
        "ms-vscode-remote.remote-containers",
        
        "pkief.material-icon-theme",
        "ms-vscode.vscode-fluent-icons",
        
        "ms-vscode.hexeditor",
        "gruntfuggly.todo-tree",
        "usernamehw.errorlens"
    ]
}
EOF

    # tasks.json
    cat > "$base_dir/.vscode/tasks.json" << 'EOF'
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "🚀 Starko: Nový AI Projekt",
            "type": "shell",
            "command": "python",
            "args": ["projects/project_manager.py", "create", "--name", "${input:projectName}"],
            "group": "build",
            "presentation": {"echo": true, "reveal": "always"}
        },
        {
            "label": "🔍 Starko: Spustit AI Testy",
            "type": "shell", 
            "command": "python",
            "args": ["tests/ai_test_runner.py", "--project", "${input:projectName}"],
            "group": "test",
            "presentation": {"echo": true, "reveal": "always"}
        },
        {
            "label": "🌐 Starko: Spustit Web GUI",
            "type": "shell",
            "command": "python",
            "args": ["web_gui/app.py"],
            "group": "build",
            "presentation": {"echo": true, "reveal": "always"}
        }
    ],
    "inputs": [
        {
            "id": "projectName",
            "type": "promptString",
            "description": "Název projektu:",
            "default": "my_project"
        }
    ]
}
EOF

    # launch.json
    cat > "$base_dir/.vscode/launch.json" << 'EOF'
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "🐍 Starko: Debug Python",
            "type": "python",
            "request": "launch",
            "program": "${file}",
            "console": "integratedTerminal",
            "justMyCode": false
        },
        {
            "name": "🧪 Starko: Spustit Testy",
            "type": "python",
            "request": "launch", 
            "program": "tests/ai_test_runner.py",
            "console": "integratedTerminal"
        },
        {
            "name": "🌐 Starko: Web Server",
            "type": "python",
            "request": "launch",
            "program": "web_gui/app.py",
            "console": "integratedTerminal"
        }
    ]
}
EOF

    log_success "Rozšířená VS Code konfigurace vytvořena"
}

# Funkce pro vytvoření interaktivního instalačního menu
create_interactive_installer() {
    log_step "Vytvářím interaktivní instalační menu..."
    
    local base_dir="$1"
    
    # Hlavní instalační skript
    cat > "$base_dir/install_starko_workspace.sh" << 'EOF'
#!/bin/bash

# =============================================
# STARKO WORKSPACE - INTERAKTIVNÍ INSTALÁTOR
# =============================================

# Barvy
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Proměnné
INSTALL_DIR="$HOME/StarkoMasterProfile"
VSCODE_DIR=""
CURRENT_STEP=0
TOTAL_STEPS=8
OS_TYPE=""

# Funkce pro logování
log_step() {
    ((CURRENT_STEP++))
    echo -e "${CYAN}[$CURRENT_STEP/$TOTAL_STEPS]${NC} $1"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Detekce OS
detect_os() {
    case "$(uname -s)" in
        Linux*)     OS_TYPE="linux";;
        Darwin*)    OS_TYPE="macos";;
        CYGWIN*)    OS_TYPE="windows";;
        MINGW*)     OS_TYPE="windows";;
        *)          OS_TYPE="unknown";;
    esac
}

# Detekce VS Code cesty
detect_vscode_path() {
    case "$OS_TYPE" in
        linux)
            VSCODE_DIR="$HOME/.config/Code/User"
            ;;
        macos)
            VSCODE_DIR="$HOME/Library/Application Support/Code/User"
            ;;
        windows)
            VSCODE_DIR="$APPDATA/Code/User"
            ;;
        *)
            VSCODE_DIR=""
            ;;
    esac
}

# Kontrola závislostí
check_dependencies() {
    log_step "Kontrola závislostí..."
    
    local missing=()
    
    if ! command -v code &> /dev/null; then
        missing+=("VS Code")
    fi
    
    if ! command -v python3 &> /dev/null; then
        missing+=("Python 3")
    fi
    
    if [ ${#missing[@]} -ne 0 ]; then
        log_error "Chybějící závislosti: ${missing[*]}"
        return 1
    fi
    
    log_success "Všechny závislosti jsou nainstalovány"
    return 0
}

# Vytvoření adresářů
create_directories() {
    log_step "Vytváření adresářů..."
    
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$INSTALL_DIR/themes"
    mkdir -p "$INSTALL_DIR/icons"
    mkdir -p "$INSTALL_DIR/snippets"
    mkdir -p "$INSTALL_DIR/backups"
    
    log_success "Adresáře vytvořeny"
}

# Instalace tématu
install_theme() {
    log_step "Instalace Starko Dark Pro tématu..."
    
    cp themes/starko-dark-pro.json "$VSCODE_DIR/"
    
    if [ $? -eq 0 ]; then
        log_success "Téma instalováno"
    else
        log_error "Chyba při instalaci tématu"
        return 1
    fi
}

# Instalace snippetů
install_snippets() {
    log_step "Instalace snippetů..."
    
    cp snippets/*.json "$VSCODE_DIR/snippets/"
    
    if [ $? -eq 0 ]; then
        log_success "Snippety instalovány"
    else
        log_error "Chyba při instalaci snippetů"
        return 1
    fi
}

# Instalace konfigurace
install_config() {
    log_step "Instalace VS Code konfigurace..."
    
    cp .vscode/settings.json "$VSCODE_DIR/"
    cp .vscode/extensions.json "$VSCODE_DIR/"
    cp .vscode/tasks.json "$VSCODE_DIR/"
    cp .vscode/launch.json "$VSCODE_DIR/"
    
    if [ $? -eq 0 ]; then
        log_success "Konfigurace instalována"
    else
        log_error "Chyba při instalaci konfigurace"
        return 1
    fi
}

# Záloha stávající konfigurace
backup_existing_config() {
    log_step "Zálohování stávající konfigurace..."
    
    local backup_dir="$INSTALL_DIR/backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    if [ -d "$VSCODE_DIR" ]; then
        cp "$VSCODE_DIR/settings.json" "$backup_dir/" 2>/dev/null
        cp "$VSCODE_DIR/extensions.json" "$backup_dir/" 2>/dev/null
        cp "$VSCODE_DIR/tasks.json" "$backup_dir/" 2>/dev/null
        cp "$VSCODE_DIR/launch.json" "$backup_dir/" 2>/dev/null
        cp -r "$VSCODE_DIR/snippets" "$backup_dir/" 2>/dev/null
    fi
    
    log_success "Záloha vytvořena: $backup_dir"
}

# Hlavní instalační funkce
main_installation() {
    echo -e "${PURPLE}"
    echo "============================================="
    echo "   STARKO WORKSPACE - INTERAKTIVNÍ INSTALACE"
    echo "============================================="
    echo -e "${NC}"
    
    detect_os
    detect_vscode_path
    
    log_info "Detekovaný OS: $OS_TYPE"
    log_info "VS Code cesta: $VSCODE_DIR"
    log_info "Instalační adresář: $INSTALL_DIR"
    
    echo
    read -p "Pokračovat v instalaci? (ano/ne): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Aa]$ ]]; then
        log_info "Instalace zrušena"
        exit 0
    fi
    
    # Provedení instalace
    backup_existing_config
    check_dependencies
    create_directories
    install_theme
    install_snippets
    install_config
    
    echo
    echo -e "${GREEN}"
    echo "============================================="
    echo "           INSTALACE DOKONČENA!"
    echo "============================================="
    echo
    echo -e "${NC}Následující kroky:"
    echo "1. Restartujte VS Code"
    echo "2. Vyberte téma: Starko Dark Pro"
    echo "3. Nainstalujte doporučená rozšíření"
    echo "4. Začněte vytvářet projekty!"
    echo
    echo -e "Pro správu workspace spusťte: ${CYAN}python web_gui/app.py${NC}"
}

# Spuštění instalace
main_installation
EOF

    chmod +x "$base_dir/install_starko_workspace.sh"

    # Windows instalační skript
    cat > "$base_dir/installers/windows/install_starko_windows.ps1" << 'EOF'
Write-Host "=============================================" -ForegroundColor Magenta
Write-Host "   STARKO WORKSPACE - WINDOWS INSTALÁTOR"
Write-Host "=============================================" -ForegroundColor Magenta

$StarkoProfile = "$env:USERPROFILE\StarkoMasterProfile"
$VSCodePath = "$env:APPDATA\Code\User"

# Vytvoření adresářů
Write-Host "[1/6] Vytváření adresářů..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path "$StarkoProfile" -Force | Out-Null
New-Item -ItemType Directory -Path "$StarkoProfile\backups" -Force | Out-Null
New-Item -ItemType Directory -Path "$VSCodePath\snippets" -Force | Out-Null

# Záloha existující konfigurace
Write-Host "[2/6] Zálohování stávající konfigurace..." -ForegroundColor Yellow
$BackupDir = "$StarkoProfile\backups\$(Get-Date -Format 'yyyyMMdd_HHmmss')"
New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null

if (Test-Path "$VSCodePath\settings.json") {
    Copy-Item "$VSCodePath\settings.json" "$BackupDir\" -Force
}
if (Test-Path "$VSCodePath\extensions.json") {
    Copy-Item "$VSCodePath\extensions.json" "$BackupDir\" -Force
}

# Kopírování tématu
Write-Host "[3/6] Instalace Starko Dark Pro tématu..." -ForegroundColor Yellow
Copy-Item ".\themes\starko-dark-pro.json" "$VSCodePath\" -Force

# Kopírování snippetů
Write-Host "[4/6] Instalace snippetů..." -ForegroundColor Yellow
Copy-Item ".\snippets\*.json" "$VSCodePath\snippets\" -Force

# Kopírování konfigurace
Write-Host "[5/6] Instalace VS Code konfigurace..." -ForegroundColor Yellow
Copy-Item ".\vscode\*.json" "$VSCodePath\" -Force

# Dokončení
Write-Host "[6/6] Dokončování instalace..." -ForegroundColor Yellow
Start-Sleep -Seconds 2

Write-Host ""
Write-Host "=============================================" -ForegroundColor Green
Write-Host "        WINDOWS INSTALACE DOKONČENA!"
Write-Host "=============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Následující kroky:" -ForegroundColor White
Write-Host "1. Restartujte VS Code"
Write-Host "2. Vyberte téma: Starko Dark Pro" 
Write-Host "3. Nainstalujte doporučená rozšíření"
Write-Host ""
Write-Host "Pro správu workspace spusťte: python web_gui/app.py" -ForegroundColor Cyan
Write-Host ""
EOF

    log_success "Interaktivní instalační menu vytvořeno"
}

# Funkce pro vytvoření vylepšeného Web GUI
create_enhanced_web_gui() {
    log_step "Vytvářím vylepšené Web GUI..."
    
    local base_dir="$1"
    
    # Hlavní app.py
    cat > "$base_dir/web_gui/app.py" << 'EOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
STARKO RPI5 AI WORKSPACE - ROZŠÍŘENÉ WEB GUI
"""

from flask import Flask, render_template, jsonify, request, send_file
from flask_cors import CORS
import os
import json
import subprocess
import psutil
import platform
from pathlib import Path
import logging
from datetime import datetime
import sqlite3

app = Flask(__name__, template_folder="templates", static_folder="static")
CORS(app)

# Konfigurace
WORKSPACE_DIR = Path(__file__).parent.parent
CONFIG_DIR = WORKSPACE_DIR / "config"
LOGS_DIR = WORKSPACE_DIR / "logs"

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class StarkoWorkspaceManager:
    def __init__(self):
        self.workspace_dir = WORKSPACE_DIR
        self.setup_database()
    
    def setup_database(self):
        """Nastaví SQLite databázi pro správu workspace"""
        db_path = self.workspace_dir / "system" / "workspace.db"
        db_path.parent.mkdir(parents=True, exist_ok=True)
        
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS projects (
                id INTEGER PRIMARY KEY,
                name TEXT UNIQUE,
                type TEXT,
                created_date TEXT,
                status TEXT
            )
        ''')
        
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS system_logs (
                id INTEGER PRIMARY KEY,
                timestamp TEXT,
                level TEXT,
                message TEXT
            )
        ''')
        
        conn.commit()
        conn.close()
    
    def get_system_info(self):
        """Získá kompletní informace o systému"""
        try:
            # Základní systémové informace
            system_info = {
                "platform": platform.system(),
                "platform_version": platform.version(),
                "architecture": platform.architecture()[0],
                "processor": platform.processor(),
                "hostname": platform.node()
            }
            
            # Výkon systému
            performance = {
                "cpu_usage": psutil.cpu_percent(interval=1),
                "cpu_cores": psutil.cpu_count(logical=False),
                "cpu_threads": psutil.cpu_count(logical=True),
                "memory_total": psutil.virtual_memory().total,
                "memory_used": psutil.virtual_memory().used,
                "memory_percent": psutil.virtual_memory().percent,
                "disk_total": psutil.disk_usage('/').total,
                "disk_used": psutil.disk_usage('/').used,
                "disk_percent": psutil.disk_usage('/').percent
            }
            
            # Teplota (RPi specific)
            temperature = self.get_cpu_temperature()
            
            # Workspace statistiky
            workspace_stats = self.get_workspace_stats()
            
            return {
                "system": system_info,
                "performance": performance,
                "temperature": temperature,
                "workspace": workspace_stats,
                "timestamp": datetime.now().isoformat()
            }
        except Exception as e:
            logger.error(f"Chyba při získávání systémových informací: {e}")
            return {}
    
    def get_cpu_temperature(self):
        """Získá teplotu CPU"""
        try:
            if os.path.exists('/sys/class/thermal/thermal_zone0/temp'):
                with open('/sys/class/thermal/thermal_zone0/temp', 'r') as f:
                    return float(f.read().strip()) / 1000.0
            return None
        except:
            return None
    
    def get_workspace_stats(self):
        """Získá statistiky workspace"""
        try:
            stats = {
                "total_projects": 0,
                "total_files": 0,
                "total_size": 0,
                "ai_models": 0,
                "scripts": 0
            }
            
            # Projekty
            projects_dir = self.workspace_dir / "projects"
            if projects_dir.exists():
                stats["total_projects"] = len([f for f in projects_dir.iterdir() if f.is_dir()])
            
            # Celkový počet souborů a velikost
            for file_path in self.workspace_dir.rglob('*'):
                if file_path.is_file():
                    stats["total_files"] += 1
                    stats["total_size"] += file_path.stat().st_size
            
            # AI modely
            models_dir = self.workspace_dir / "ai_engine" / "models"
            if models_dir.exists():
                stats["ai_models"] = len([f for f in models_dir.iterdir() if f.is_file()])
            
            # Scripty
            scripts_dir = self.workspace_dir / "scripts"
            if scripts_dir.exists():
                stats["scripts"] = len([f for f in scripts_dir.rglob('*.py') if f.is_file()])
            
            # Převod velikosti na MB
            stats["total_size_mb"] = round(stats["total_size"] / (1024 * 1024), 2)
            
            return stats
        except Exception as e:
            logger.error(f"Chyba při získávání statistik workspace: {e}")
            return {}
    
    def create_project(self, project_data):
        """Vytvoří nový projekt"""
        try:
            project_name = project_data.get('name', '').strip()
            project_type = project_data.get('type', 'standard')
            
            if not project_name:
                return {"status": "error", "message": "Název projektu je povinný"}
            
            project_path = self.workspace_dir / "projects" / project_name
            if project_path.exists():
                return {"status": "error", "message": "Projekt již existuje"}
            
            # Vytvoření struktury projektu
            project_path.mkdir(parents=True)
            (project_path / "src").mkdir()
            (project_path / "tests").mkdir()
            (project_path / "docs").mkdir()
            (project_path / "config").mkdir()
            
            # Hlavní soubor projektu
            main_file = project_path / "src" / "main.py"
            main_content = f'''#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
PROJEKT: {project_name}
TYP: {project_type}
STARKO WORKSPACE - {datetime.now().year}
"""

import os
from pathlib import Path

def main():
    """Hlavní funkce projektu"""
    print("🚀 Vítejte v projektu {project_name}!")
    print(f"📍 Cesta: {project_path}")
    
    # TODO: Přidejte svůj kód zde
    
    print("✅ Projekt úspěšně spuštěn!")

if __name__ == "__main__":
    main()
'''
            with open(main_file, 'w') as f:
                f.write(main_content)
            
            # Konfigurace projektu
            config = {
                "project_name": project_name,
                "type": project_type,
                "version": "1.0.0",
                "created": datetime.now().isoformat(),
                "author": "Starko Master"
            }
            
            config_file = project_path / "config" / "project.json"
            with open(config_file, 'w') as f:
                json.dump(config, f, indent=2)
            
            # Uložení do databáze
            conn = sqlite3.connect(self.workspace_dir / "system" / "workspace.db")
            cursor = conn.cursor()
            cursor.execute(
                "INSERT INTO projects (name, type, created_date, status) VALUES (?, ?, ?, ?)",
                (project_name, project_type, datetime.now().isoformat(), "active")
            )
            conn.commit()
            conn.close()
            
            return {"status": "success", "message": f"Projekt '{project_name}' vytvořen"}
            
        except Exception as e:
            return {"status": "error", "message": f"Chyba při vytváření projektu: {str(e)}"}
    
    def get_projects(self):
        """Získá seznam všech projektů"""
        try:
            conn = sqlite3.connect(self.workspace_dir / "system" / "workspace.db")
            cursor = conn.cursor()
            cursor.execute("SELECT name, type, created_date, status FROM projects ORDER BY created_date DESC")
            projects = cursor.fetchall()
            conn.close()
            
            return [
                {
                    "name": name,
                    "type": type_,
                    "created_date": created_date,
                    "status": status
                }
                for name, type_, created_date, status in projects
            ]
        except Exception as e:
            logger.error(f"Chyba při získávání projektů: {e}")
            return []
    
    def install_vscode_extensions(self):
        """Nainstaluje doporučená VS Code rozšíření"""
        try:
            extensions_file = self.workspace_dir / ".vscode" / "extensions.json"
            with open(extensions_file, 'r') as f:
                extensions_data = json.load(f)
            
            extensions = extensions_data.get("recommendations", [])
            installed = []
            failed = []
            
            for extension in extensions:
                try:
                    result = subprocess.run([
                        "code", "--install-extension", extension
                    ], capture_output=True, text=True, timeout=60)
                    
                    if result.returncode == 0:
                        installed.append(extension)
                    else:
                        failed.append(extension)
                except Exception as e:
                    failed.append(extension)
                    logger.error(f"Chyba při instalaci {extension}: {e}")
            
            return {
                "status": "success",
                "installed": installed,
                "failed": failed,
                "total": len(extensions)
            }
        except Exception as e:
            return {"status": "error", "message": f"Chyba při instalaci rozšíření: {str(e)}"}

# Vytvoření instance správce
workspace_manager = StarkoWorkspaceManager()

@app.route('/')
def index():
    """Hlavní dashboard"""
    return render_template('dashboard.html')

@app.route('/api/system/status')
def system_status():
    """API pro systémový status"""
    status = workspace_manager.get_system_info()
    return jsonify(status)

@app.route('/api/projects', methods=['GET', 'POST'])
def handle_projects():
    """API pro správu projektů"""
    if request.method == 'GET':
        projects = workspace_manager.get_projects()
        return jsonify(projects)
    elif request.method == 'POST':
        project_data = request.get_json()
        result = workspace_manager.create_project(project_data)
        return jsonify(result)

@app.route('/api/projects/<project_name>', methods=['DELETE'])
def delete_project(project_name):
    """Smazání projektu"""
    try:
        project_path = WORKSPACE_DIR / "projects" / project_name
        if project_path.exists():
            import shutil
            shutil.rmtree(project_path)
            
            # Odstranění z databáze
            conn = sqlite3.connect(WORKSPACE_DIR / "system" / "workspace.db")
            cursor = conn.cursor()
            cursor.execute("DELETE FROM projects WHERE name = ?", (project_name,))
            conn.commit()
            conn.close()
            
            return jsonify({"status": "success", "message": f"Projekt '{project_name}' smazán"})
        else:
            return jsonify({"status": "error", "message": "Projekt neexistuje"})
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)})

@app.route('/api/vscode/install-extensions', methods=['POST'])
def install_extensions():
    """Instalace VS Code rozšíření"""
    result = workspace_manager.install_vscode_extensions()
    return jsonify(result)

@app.route('/api/workspace/backup', methods=['POST'])
def create_backup():
    """Vytvoření zálohy workspace"""
    try:
        backup_dir = WORKSPACE_DIR / "backups"
        backup_dir.mkdir(exist_ok=True)
        
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_name = f"starko_backup_{timestamp}"
        backup_path = backup_dir / backup_name
        
        import shutil
        shutil.make_archive(str(backup_path), 'zip', str(WORKSPACE_DIR))
        
        return jsonify({
            "status": "success", 
            "message": "Záloha vytvořena",
            "backup_file": f"{backup_name}.zip"
        })
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)})

@app.route('/api/ai/generate-code', methods=['POST'])
def generate_code():
    """Generování kódu pomocí AI"""
    try:
        data = request.get_json()
        prompt = data.get('prompt', '')
        
        if not prompt:
            return jsonify({"status": "error", "message": "Prompt je povinný"})
        
        # Zde by byla integrace s AI API
        # Prozatím vrátíme ukázkový kód
        generated_code = f'''# AI GENEROVANÝ KÓD
# Prompt: {prompt}
# Generováno: {datetime.now().isoformat()}

def ai_generated_function():
    """Funkce generovaná AI na základě vašeho promptu"""
    print("🎯 Tento kód byl generován AI")
    # TODO: Implementujte funkcionalitu podle promptu
    
    return "AI Generation Complete"

if __name__ == "__main__":
    result = ai_generated_function()
    print(result)
'''
        
        return jsonify({
            "status": "success",
            "code": generated_code,
            "suggestions": [
                "Přidejte error handling",
                "Optimalizujte výkon",
                "Dokumentujte funkce"
            ]
        })
        
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080, debug=True)
EOF

    # Vytvoření moderního dashboard template
    cat > "$base_dir/web_gui/templates/dashboard.html" << 'EOF'
<!DOCTYPE html>
<html lang="cs">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Starko RPi5 AI Workspace - Dashboard</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/apexcharts"></script>
    <style>
        :root {
            --starko-primary: #6F9CF4;
            --starko-secondary: #4FC1FF;
            --starko-accent: #D89CFF;
            --starko-success: #8FCE6C;
            --starko-warning: #FFB86C;
            --starko-danger: #FF6B6B;
            --starko-dark: #0D0F14;
            --starko-darker: #0A0B0F;
            --starko-light: #1A1D22;
            --starko-lighter: #252A32;
            --starko-text: #E4E8EF;
            --starko-text-secondary: #AAB2C0;
        }
        
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, var(--starko-dark) 0%, var(--starko-darker) 100%);
            color: var(--starko-text);
            min-height: 100vh;
            overflow-x: hidden;
        }
        
        .container {
            max-width: 1400px;
            margin: 0 auto;
            padding: 20px;
        }
        
        .header {
            background: rgba(26, 29, 34, 0.8);
            backdrop-filter: blur(20px);
            border-radius: 20px;
            padding: 30px;
            margin-bottom: 25px;
            border: 1px solid var(--starko-lighter);
            box-shadow: 0 20px 40px rgba(0,0,0,0.3);
        }
        
        .header h1 {
            font-size: 2.8em;
            background: linear-gradient(135deg, var(--starko-primary), var(--starko-accent));
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            margin-bottom: 10px;
        }
        
        .header .subtitle {
            color: var(--starko-text-secondary);
            font-size: 1.2em;
            margin-bottom: 20px;
        }
        
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        
        .stat-card {
            background: linear-gradient(135deg, var(--starko-light), var(--starko-lighter));
            border-radius: 15px;
            padding: 25px;
            border: 1px solid rgba(255,255,255,0.1);
            transition: all 0.3s ease;
            position: relative;
            overflow: hidden;
        }
        
        .stat-card::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            height: 3px;
            background: linear-gradient(90deg, var(--starko-primary), var(--starko-accent));
        }
        
        .stat-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 15px 30px rgba(0,0,0,0.4);
        }
        
        .stat-card.cpu::before { background: var(--starko-primary); }
        .stat-card.memory::before { background: var(--starko-success); }
        .stat-card.disk::before { background: var(--starko-warning); }
        .stat-card.temperature::before { background: var(--starko-danger); }
        
        .stat-value {
            font-size: 2.2em;
            font-weight: bold;
            margin-bottom: 5px;
        }
        
        .stat-label {
            color: var(--starko-text-secondary);
            font-size: 0.9em;
        }
        
        .dashboard-grid {
            display: grid;
            grid-template-columns: 2fr 1fr;
            gap: 25px;
            margin-bottom: 30px;
        }
        
        .main-panel {
            display: flex;
            flex-direction: column;
            gap: 25px;
        }
        
        .panel {
            background: rgba(26, 29, 34, 0.8);
            backdrop-filter: blur(20px);
            border-radius: 15px;
            padding: 25px;
            border: 1px solid var(--starko-lighter);
        }
        
        .panel-header {
            display: flex;
            justify-content: between;
            align-items: center;
            margin-bottom: 20px;
        }
        
        .panel-title {
            font-size: 1.4em;
            font-weight: 600;
            color: var(--starko-text);
        }
        
        .btn {
            background: linear-gradient(135deg, var(--starko-primary), var(--starko-secondary));
            color: white;
            border: none;
            padding: 12px 24px;
            border-radius: 10px;
            cursor: pointer;
            font-weight: 600;
            transition: all 0.3s ease;
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            gap: 8px;
        }
        
        .btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 10px 20px rgba(111, 156, 244, 0.3);
        }
        
        .btn-success { background: linear-gradient(135deg, var(--starko-success), #6BCF7F); }
        .btn-warning { background: linear-gradient(135deg, var(--starko-warning), #FFA94D); }
        .btn-danger { background: linear-gradient(135deg, var(--starko-danger), #FF8787); }
        
        .projects-list {
            display: grid;
            gap: 15px;
        }
        
        .project-item {
            background: var(--starko-light);
            padding: 20px;
            border-radius: 10px;
            border-left: 4px solid var(--starko-primary);
            transition: all 0.3s ease;
        }
        
        .project-item:hover {
            background: var(--starko-lighter);
            transform: translateX(5px);
        }
        
        .project-name {
            font-weight: 600;
            margin-bottom: 5px;
        }
        
        .project-meta {
            color: var(--starko-text-secondary);
            font-size: 0.9em;
        }
        
        .quick-actions {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
            gap: 15px;
        }
        
        .action-btn {
            background: var(--starko-light);
            border: 1px solid var(--starko-lighter);
            padding: 20px;
            border-radius: 10px;
            text-align: center;
            cursor: pointer;
            transition: all 0.3s ease;
        }
        
        .action-btn:hover {
            background: var(--starko-lighter);
            border-color: var(--starko-primary);
            transform: translateY(-3px);
        }
        
        .action-icon {
            font-size: 2em;
            margin-bottom: 10px;
        }
        
        .modal {
            display: none;
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0,0,0,0.8);
            backdrop-filter: blur(10px);
            z-index: 1000;
            align-items: center;
            justify-content: center;
        }
        
        .modal-content {
            background: var(--starko-light);
            border-radius: 20px;
            padding: 30px;
            width: 90%;
            max-width: 500px;
            border: 1px solid var(--starko-lighter);
        }
        
        .form-group {
            margin-bottom: 20px;
        }
        
        .form-label {
            display: block;
            margin-bottom: 8px;
            color: var(--starko-text);
            font-weight: 600;
        }
        
        .form-input {
            width: 100%;
            padding: 12px 15px;
            border: 1px solid var(--starko-lighter);
            border-radius: 10px;
            background: var(--starko-dark);
            color: var(--starko-text);
            font-size: 1em;
        }
        
        .form-input:focus {
            outline: none;
            border-color: var(--starko-primary);
        }
        
        .loading {
            text-align: center;
            padding: 40px;
            color: var(--starko-text-secondary);
        }
        
        .progress-bar {
            width: 100%;
            height: 6px;
            background: var(--starko-dark);
            border-radius: 3px;
            overflow: hidden;
            margin: 10px 0;
        }
        
        .progress-fill {
            height: 100%;
            background: linear-gradient(90deg, var(--starko-primary), var(--starko-accent));
            transition: width 0.3s ease;
        }
        
        @media (max-width: 768px) {
            .dashboard-grid {
                grid-template-columns: 1fr;
            }
            
            .header h1 {
                font-size: 2em;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🤖 Starko RPi5 AI Workspace</h1>
            <div class="subtitle">Kompletní vývojové prostředí s AI integrací</div>
            <div class="quick-actions">
                <div class="action-btn" onclick="showModal('createProjectModal')">
                    <div class="action-icon">➕</div>
                    <div>Nový Projekt</div>
                </div>
                <div class="action-btn" onclick="installVSCodeExtensions()">
                    <div class="action-icon">🔧</div>
                    <div>Rozšíření</div>
                </div>
                <div class="action-btn" onclick="createBackup()">
                    <div class="action-icon">💾</div>
                    <div>Záloha</div>
                </div>
                <div class="action-btn" onclick="showModal('aiGeneratorModal')">
                    <div class="action-icon">🤖</div>
                    <div>AI Generátor</div>
                </div>
            </div>
        </div>

        <div class="stats-grid" id="systemStats">
            <div class="stat-card cpu">
                <div class="stat-value" id="cpuUsage">0%</div>
                <div class="stat-label">Využití CPU</div>
                <div class="progress-bar">
                    <div class="progress-fill" id="cpuProgress" style="width: 0%"></div>
                </div>
            </div>
            <div class="stat-card memory">
                <div class="stat-value" id="memoryUsage">0%</div>
                <div class="stat-label">Využití RAM</div>
                <div class="progress-bar">
                    <div class="progress-fill" id="memoryProgress" style="width: 0%"></div>
                </div>
            </div>
            <div class="stat-card disk">
                <div class="stat-value" id="diskUsage">0%</div>
                <div class="stat-label">Využití Disku</div>
                <div class="progress-bar">
                    <div class="progress-fill" id="diskProgress" style="width: 0%"></div>
                </div>
            </div>
            <div class="stat-card temperature">
                <div class="stat-value" id="temperature">0°C</div>
                <div class="stat-label">Teplota CPU</div>
            </div>
        </div>

        <div class="dashboard-grid">
            <div class="main-panel">
                <div class="panel">
                    <div class="panel-header">
                        <div class="panel-title">📂 Projekty</div>
                        <button class="btn" onclick="showModal('createProjectModal')">Nový Projekt</button>
                    </div>
                    <div class="projects-list" id="projectsList">
                        <div class="loading">Načítání projektů...</div>
                    </div>
                </div>
                
                <div class="panel">
                    <div class="panel-header">
                        <div class="panel-title">📊 Výkon Systému</div>
                    </div>
                    <div id="performanceChart" style="height: 300px;"></div>
                </div>
            </div>
            
            <div class="side-panel">
                <div class="panel">
                    <div class="panel-header">
                        <div class="panel-title">⚡ Rychlé Akce</div>
                    </div>
                    <div style="display: flex; flex-direction: column; gap: 10px;">
                        <button class="btn" onclick="openVSCode()">🔮 Otevřít VS Code</button>
                        <button class="btn btn-success" onclick="openTerminal()">💻 Otevřít Terminal</button>
                        <button class="btn btn-warning" onclick="runTests()">🧪 Spustit Testy</button>
                        <button class="btn btn-danger" onclick="showModal('settingsModal')">⚙️ Nastavení</button>
                    </div>
                </div>
                
                <div class="panel">
                    <div class="panel-header">
                        <div class="panel-title">ℹ️ Informace o Workspace</div>
                    </div>
                    <div id="workspaceInfo">
                        <div class="loading">Načítání informací...</div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- Modální okna -->
    <div class="modal" id="createProjectModal">
        <div class="modal-content">
            <h3>🚀 Vytvořit Nový Projekt</h3>
            <form onsubmit="createProject(event)">
                <div class="form-group">
                    <label class="form-label">Název projektu</label>
                    <input type="text" class="form-input" id="projectName" required>
                </div>
                <div class="form-group">
                    <label class="form-label">Typ projektu</label>
                    <select class="form-input" id="projectType">
                        <option value="standard">Standardní</option>
                        <option value="ai">AI Projekt</option>
                        <option value="web">Webová aplikace</option>
                        <option value="iot">IoT Projekt</option>
                    </select>
                </div>
                <div style="display: flex; gap: 10px; margin-top: 20px;">
                    <button type="submit" class="btn">Vytvořit Projekt</button>
                    <button type="button" class="btn btn-danger" onclick="hideModal('createProjectModal')">Zrušit</button>
                </div>
            </form>
        </div>
    </div>

    <div class="modal" id="aiGeneratorModal">
        <div class="modal-content">
            <h3>🤖 AI Generátor Kódu</h3>
            <div class="form-group">
                <label class="form-label">Popište co chcete vygenerovat</label>
                <textarea class="form-input" id="aiPrompt" rows="5" placeholder="Např.: Funkce pro čtení teplotního senzoru..."></textarea>
            </div>
            <div style="display: flex; gap: 10px;">
                <button class="btn" onclick="generateCode()">Generovat Kód</button>
                <button class="btn btn-danger" onclick="hideModal('aiGeneratorModal')">Zrušit</button>
            </div>
            <div id="aiResult" style="margin-top: 20px; display: none;">
                <pre style="background: var(--starko-dark); padding: 15px; border-radius: 10px; overflow: auto;"></pre>
            </div>
        </div>
    </div>

    <script>
        // Globální proměnné
        let systemData = {};
        let projects = [];
        let performanceChart;

        // Načtení systémového statusu
        async function loadSystemStatus() {
            try {
                const response = await fetch('/api/system/status');
                systemData = await response.json();
                updateSystemStats();
                updateWorkspaceInfo();
            } catch (error) {
                console.error('Chyba při načítání statusu:', error);
            }
        }

        // Aktualizace systémových statistik
        function updateSystemStats() {
            if (!systemData.performance) return;

            const perf = systemData.performance;
            
            // CPU
            document.getElementById('cpuUsage').textContent = `${perf.cpu_usage}%`;
            document.getElementById('cpuProgress').style.width = `${perf.cpu_usage}%`;
            
            // Memory
            document.getElementById('memoryUsage').textContent = `${perf.memory_percent}%`;
            document.getElementById('memoryProgress').style.width = `${perf.memory_percent}%`;
            
            // Disk
            document.getElementById('diskUsage').textContent = `${perf.disk_percent}%`;
            document.getElementById('diskProgress').style.width = `${perf.disk_percent}%`;
            
            // Temperature
            const temp = systemData.temperature;
            document.getElementById('temperature').textContent = temp ? `${temp}°C` : 'N/A';
        }

        // Načtení projektů
        async function loadProjects() {
            try {
                const response = await fetch('/api/projects');
                projects = await response.json();
                updateProjectsList();
            } catch (error) {
                console.error('Chyba při načítání projektů:', error);
            }
        }

        // Aktualizace seznamu projektů
        function updateProjectsList() {
            const container = document.getElementById('projectsList');
            
            if (projects.length === 0) {
                container.innerHTML = '<div class="loading">Žádné projekty. Vytvořte první projekt!</div>';
                return;
            }

            let html = '';
            projects.forEach(project => {
                html += `
                    <div class="project-item">
                        <div class="project-name">${project.name}</div>
                        <div class="project-meta">
                            Typ: ${project.type} | Vytvořeno: ${new Date(project.created_date).toLocaleDateString()}
                        </div>
                        <div style="margin-top: 10px; display: flex; gap: 10px;">
                            <button class="btn" onclick="openProject('${project.name}')">Otevřít</button>
                            <button class="btn btn-danger" onclick="deleteProject('${project.name}')">Smazat</button>
                        </div>
                    </div>
                `;
            });
            
            container.innerHTML = html;
        }

        // Aktualizace informací o workspace
        function updateWorkspaceInfo() {
            const container = document.getElementById('workspaceInfo');
            if (!systemData.workspace) return;

            const ws = systemData.workspace;
            container.innerHTML = `
                <div style="display: flex; flex-direction: column; gap: 10px;">
                    <div><strong>Projektů:</strong> ${ws.total_projects}</div>
                    <div><strong>Souborů:</strong> ${ws.total_files}</div>
                    <div><strong>Velikost:</strong> ${ws.total_size_mb} MB</div>
                    <div><strong>AI Modelů:</strong> ${ws.ai_models}</div>
                    <div><strong>Scriptů:</strong> ${ws.scripts}</div>
                </div>
            `;
        }

        // Vytvoření nového projektu
        async function createProject(event) {
            event.preventDefault();
            
            const projectData = {
                name: document.getElementById('projectName').value,
                type: document.getElementById('projectType').value
            };

            try {
                const response = await fetch('/api/projects', {
                    method: 'POST',
                    headers: {'Content-Type': 'application/json'},
                    body: JSON.stringify(projectData)
                });
                
                const result = await response.json();
                
                if (result.status === 'success') {
                    alert(result.message);
                    hideModal('createProjectModal');
                    loadProjects();
                } else {
                    alert('Chyba: ' + result.message);
                }
            } catch (error) {
                alert('Chyba při vytváření projektu: ' + error);
            }
        }

        // Generování kódu AI
        async function generateCode() {
            const prompt = document.getElementById('aiPrompt').value;
            if (!prompt) {
                alert('Zadejte prompt pro AI!');
                return;
            }

            try {
                const response = await fetch('/api/ai/generate-code', {
                    method: 'POST',
                    headers: {'Content-Type': 'application/json'},
                    body: JSON.stringify({prompt: prompt})
                });
                
                const result = await response.json();
                const resultDiv = document.getElementById('aiResult');
                
                if (result.status === 'success') {
                    resultDiv.style.display = 'block';
                    resultDiv.querySelector('pre').textContent = result.code;
                } else {
                    alert('Chyba: ' + result.message);
                }
            } catch (error) {
                alert('Chyba při generování: ' + error);
            }
        }

        // Instalace VS Code rozšíření
        async function installVSCodeExtensions() {
            if (!confirm('Nainstalovat všechna doporučená VS Code rozšíření?')) return;

            try {
                const response = await fetch('/api/vscode/install-extensions', {
                    method: 'POST'
                });
                
                const result = await response.json();
                
                if (result.status === 'success') {
                    alert(`Rozšíření nainstalována: ${result.installed.length}/${result.total}\nChyby: ${result.failed.length}`);
                } else {
                    alert('Chyba: ' + result.message);
                }
            } catch (error) {
                alert('Chyba při instalaci rozšíření: ' + error);
            }
        }

        // Vytvoření zálohy
        async function createBackup() {
            try {
                const response = await fetch('/api/workspace/backup', {
                    method: 'POST'
                });
                
                const result = await response.json();
                alert(result.message);
            } catch (error) {
                alert('Chyba při vytváření zálohy: ' + error);
            }
        }

        // Smazání projektu
        async function deleteProject(projectName) {
            if (!confirm(`Opravdu chcete smazat projekt "${projectName}"?`)) return;

            try {
                const response = await fetch(`/api/projects/${projectName}`, {
                    method: 'DELETE'
                });
                
                const result = await response.json();
                
                if (result.status === 'success') {
                    alert(result.message);
                    loadProjects();
                } else {
                    alert('Chyba: ' + result.message);
                }
            } catch (error) {
                alert('Chyba při mazání projektu: ' + error);
            }
        }

        // Správa modálních oken
        function showModal(modalId) {
            document.getElementById(modalId).style.display = 'flex';
        }

        function hideModal(modalId) {
            document.getElementById(modalId).style.display = 'none';
        }

        // Pomocné funkce
        function openVSCode() {
            alert('Otevírám VS Code... (funkce vyžaduje nastavení)');
        }

        function openTerminal() {
            alert('Otevírám terminál...');
        }

        function runTests() {
            alert('Spouštím testy...');
        }

        function openProject(projectName) {
            alert(`Otevírám projekt ${projectName}...`);
        }

        // Inicializace
        document.addEventListener('DOMContentLoaded', function() {
            loadSystemStatus();
            loadProjects();
            
            // Automatická aktualizace každých 5 sekund
            setInterval(loadSystemStatus, 5000);
            
            // Zavření modálního okna kliknutím mimo
            document.addEventListener('click', function(event) {
                if (event.target.classList.contains('modal')) {
                    event.target.style.display = 'none';
                }
            });
        });
    </script>
</body>
</html>
EOF

    log_success "Vylepšené Web GUI vytvořeno"
}

# Funkce pro vytvoření AI engine souborů
create_ai_engine() {
    log_step "Vytvářím AI engine..."
    
    local base_dir="$1"
    
    # local_ai.py
    cat > "$base_dir/ai_engine/local_ai.py" << 'EOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
POKROČILÝ LOKÁLNÍ AI MODUL PRO STARKO WORKSPACE
"""

import json
import pickle
import sqlite3
from pathlib import Path
from typing import Dict, List, Optional
import datetime
import logging

class StarkoAIEngine:
    def __init__(self, workspace_root: str = "."):
        self.workspace_root = Path(workspace_root)
        self.memory_path = self.workspace_root / "ai_engine" / "memory"
        self.models_path = self.workspace_root / "ai_engine" / "models"
        self.memory_path.mkdir(parents=True, exist_ok=True)
        self.models_path.mkdir(parents=True, exist_ok=True)
        
        self.setup_database()
        self.logger = self.setup_logging()
        
        self.logger.info("🤖 Starko AI Engine initialized!")
    
    def setup_database(self):
        """Nastaví databázi pro AI paměť"""
        db_path = self.memory_path / "ai_memory.db"
        self.conn = sqlite3.connect(db_path)
        cursor = self.conn.cursor()
        
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS code_patterns (
                id INTEGER PRIMARY KEY,
                pattern_type TEXT,
                code_snippet TEXT,
                context TEXT,
                language TEXT,
                efficiency_score REAL,
                timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS project_templates (
                id INTEGER PRIMARY KEY,
                name TEXT UNIQUE,
                template_type TEXT,
                structure TEXT,
                common_files TEXT,
                description TEXT
            )
        ''')
        
        self.conn.commit()
    
    def setup_logging(self):
        """Nastaví logging pro AI engine"""
        log_path = self.workspace_root / "logs" / "ai_engine.log"
        log_path.parent.mkdir(parents=True, exist_ok=True)
        
        logger = logging.getLogger('StarkoAI')
        logger.setLevel(logging.INFO)
        
        handler = logging.FileHandler(log_path)
        formatter = logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
        handler.setFormatter(formatter)
        logger.addHandler(handler)
        
        return logger
    
    def learn_from_code(self, code: str, context: Dict, language: str = "python"):
        """Učí se z kódu a ukládá vzory"""
        try:
            cursor = self.conn.cursor()
            
            # Analýza kódu
            pattern_type = self.analyze_code_pattern(code, context)
            efficiency_score = self.estimate_efficiency(code, language)
            
            cursor.execute('''
                INSERT INTO code_patterns 
                (pattern_type, code_snippet, context, language, efficiency_score)
                VALUES (?, ?, ?, ?, ?)
            ''', (pattern_type, code, json.dumps(context), language, efficiency_score))
            
            self.conn.commit()
            self.logger.info(f"📚 AI se naučila nový pattern: {pattern_type}")
            
        except Exception as e:
            self.logger.error(f"Chyba při učení z kódu: {e}")
    
    def analyze_code_pattern(self, code: str, context: Dict) -> str:
        """Analyzuje vzor v kódu"""
        code_lower = code.lower()
        
        if any(keyword in code_lower for keyword in ['class', 'def __init__']):
            return "class_definition"
        elif 'def ' in code_lower:
            return "function_definition"
        elif any(keyword in code_lower for keyword in ['for ', 'while ']):
            return "loop"
        elif 'if ' in code_lower:
            return "conditional"
        elif any(keyword in code_lower for keyword in ['import ', 'from ']):
            return "import"
        else:
            return "general"
    
    def estimate_efficiency(self, code: str, language: str) -> float:
        """Odhaduje efektivitu kódu (0-1)"""
        # Základní analýza efektivity
        score = 0.5  # Základní skóre
        
        # Jednoduché heuristiky pro Python
        if language == "python":
            lines = code.split('\n')
            if len(lines) < 20:
                score += 0.2  # Krátký kód
            if 'for ' in code and 'range(' in code:
                score += 0.1  # Používá range
            if 'list comprehension' in code.lower():
                score += 0.2  # List comprehension
        
        return min(score, 1.0)
    
    def generate_suggestion(self, prompt: str, context: Dict = None) -> Dict:
        """Generuje návrh kódu na základě promptu"""
        try:
            # Načtení relevantních patternů z databáze
            cursor = self.conn.cursor()
            cursor.execute('''
                SELECT code_snippet, efficiency_score 
                FROM code_patterns 
                WHERE pattern_type != 'import'
                ORDER BY efficiency_score DESC 
                LIMIT 5
            ''')
            
            patterns = cursor.fetchall()
            
            # Generování kódu na základě patternů
            generated_code = self.generate_code_from_patterns(prompt, patterns, context)
            
            suggestion = {
                "code": generated_code,
                "patterns_used": len(patterns),
                "timestamp": datetime.datetime.now().isoformat(),
                "efficiency_score": self.estimate_efficiency(generated_code, "python"),
                "suggestions": self.generate_improvement_suggestions(generated_code)
            }
            
            self.logger.info(f"🎯 AI vygenerovala návrh pro: {prompt}")
            return suggestion
            
        except Exception as e:
            self.logger.error(f"Chyba při generování návrhu: {e}")
            return {
                "code": f"# Chyba při generování: {e}",
                "patterns_used": 0,
                "timestamp": datetime.datetime.now().isoformat(),
                "efficiency_score": 0.0,
                "suggestions": ["Opravte chybu v AI engine"]
            }
    
    def generate_code_from_patterns(self, prompt: str, patterns: List, context: Dict = None) -> str:
        """Generuje kód na základě naučených patternů"""
        base_code = f'''# AI GENEROVANÝ KÓD
# Prompt: {prompt}
# Generováno: {datetime.datetime.now().isoformat()}
# Starko AI Engine

"""
Funkce generovaná AI na základě vašeho promptu.
"""

def ai_generated_function():
    """Hlavní funkce generovaná AI"""
    print("🚀 AI generovaná funkce byla spuštěna")
    
    # TODO: Implementujte funkcionalitu podle promptu
    # {prompt}
    
    result = "AI Generation Complete"
    return result

if __name__ == "__main__":
    output = ai_generated_function()
    print(f"✅ Výsledek: {output}")
'''
        
        return base_code
    
    def generate_improvement_suggestions(self, code: str) -> List[str]:
        """Generuje návrhy na zlepšení kódu"""
        suggestions = []
        
        if 'TODO' in code:
            suggestions.append("Odstraňte TODO komentáře a implementujte funkcionalitu")
        
        if 'print(' in code and 'logging' not in code:
            suggestions.append("Zvažte použití logging místo print pro lepší správu výstupu")
        
        if code.count('\n') > 50:
            suggestions.append("Zvažte rozdělení kódu na menší funkce")
        
        if not any(keyword in code for keyword in ['def ', 'class ']):
            suggestions.append("Přidejte funkce nebo třídy pro lepší organizaci kódu")
        
        return suggestions
    
    def create_project_template(self, template_name: str, template_type: str, structure: Dict):
        """Vytvoří šablonu projektu"""
        try:
            cursor = self.conn.cursor()
            cursor.execute('''
                INSERT OR REPLACE INTO project_templates 
                (name, template_type, structure, common_files, description)
                VALUES (?, ?, ?, ?, ?)
            ''', (
                template_name, 
                template_type, 
                json.dumps(structure),
                json.dumps(self.get_common_files(template_type)),
                f"Šablona pro {template_type} projekty"
            ))
            
            self.conn.commit()
            self.logger.info(f"📁 Vytvořena šablona projektu: {template_name}")
            
        except Exception as e:
            self.logger.error(f"Chyba při vytváření šablony: {e}")
    
    def get_common_files(self, project_type: str) -> List[str]:
        """Vrátí seznam běžných souborů pro typ projektu"""
        common_files = {
            "python": ["main.py", "requirements.txt", "README.md", "config.json"],
            "web": ["index.html", "style.css", "app.js", "package.json"],
            "ai": ["model.py", "train.py", "utils.py", "config.yaml"],
            "iot": ["sensor_reader.py", "config.py", "main_loop.py"]
        }
        
        return common_files.get(project_type, ["main.py", "README.md"])

def main():
    """Hlavní funkce pro testování AI engine"""
    ai = StarkoAIEngine()
    
    # Testovací příklad
    test_prompt = "Funkce pro čtení teplotního senzoru na RPi"
    suggestion = ai.generate_suggestion(test_prompt)
    
    print("🤖 STARKO AI ENGINE - TEST")
    print("=" * 40)
    print(f"Prompt: {test_prompt}")
    print(f"Generovaný kód:\n{suggestion['code']}")
    print(f"Efektivita: {suggestion['efficiency_score']:.2f}")
    print(f"Návrhy: {', '.join(suggestion['suggestions'])}")

if __name__ == "__main__":
    main()
EOF

    # memory_system.py
    cat > "$base_dir/ai_engine/memory_system.py" << 'EOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
ROZŠÍŘENÝ SYSTÉM PAMĚTI PRO STARKO AI
"""

import sqlite3
import json
from pathlib import Path
from datetime import datetime

class AdvancedMemorySystem:
    def __init__(self, db_path: str = "ai_memory.db"):
        self.db_path = Path(db_path)
        self.init_database()
    
    def init_database(self):
        """Inicializuje pokročilou databázi paměti"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        # Tabulka pro vzory kódu
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS code_patterns (
                id INTEGER PRIMARY KEY,
                pattern_type TEXT,
                code_snippet TEXT,
                context TEXT,
                language TEXT,
                efficiency_score REAL,
                usage_count INTEGER DEFAULT 0,
                timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        
        # Tabulka pro chyby a řešení
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS error_solutions (
                id INTEGER PRIMARY KEY,
                error_type TEXT,
                error_message TEXT,
                solution TEXT,
                programming_language TEXT,
                occurrence_count INTEGER DEFAULT 1,
                last_occurrence DATETIME DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        
        # Tabulka pro optimalizace
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS optimizations (
                id INTEGER PRIMARY KEY,
                optimization_type TEXT,
                before_code TEXT,
                after_code TEXT,
                improvement_percent REAL,
                context TEXT
            )
        ''')
        
        conn.commit()
        conn.close()
        print("✅ Rozšířená databáze paměti inicializována")
    
    def record_error_solution(self, error_type: str, error_message: str, solution: str, language: str = "python"):
        """Zaznamená chybu a její řešení"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        # Kontrola jestli chyba již existuje
        cursor.execute('''
            SELECT id, occurrence_count FROM error_solutions 
            WHERE error_type = ? AND error_message = ?
        ''', (error_type, error_message))
        
        result = cursor.fetchone()
        
        if result:
            # Aktualizace existující chyby
            cursor.execute('''
                UPDATE error_solutions 
                SET occurrence_count = occurrence_count + 1,
                    last_occurrence = CURRENT_TIMESTAMP
                WHERE id = ?
            ''', (result[0],))
        else:
            # Nový záznam chyby
            cursor.execute('''
                INSERT INTO error_solutions 
                (error_type, error_message, solution, programming_language)
                VALUES (?, ?, ?, ?)
            ''', (error_type, error_message, solution, language))
        
        conn.commit()
        conn.close()
    
    def get_solution_for_error(self, error_message: str) -> str:
        """Najde řešení pro chybu"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute('''
            SELECT solution, occurrence_count 
            FROM error_solutions 
            WHERE error_message LIKE ? 
            ORDER BY occurrence_count DESC 
            LIMIT 1
        ''', (f'%{error_message}%',))
        
        result = cursor.fetchone()
        conn.close()
        
        if result:
            return result[0]
        else:
            return "Řešení pro tuto chybu nebylo nalezeno v paměti."

def main():
    memory = AdvancedMemorySystem()
    print("✅ Advanced Memory System je připraven")

if __name__ == "__main__":
    main()
EOF

    chmod +x "$base_dir/ai_engine/local_ai.py"
    chmod +x "$base_dir/ai_engine/memory_system.py"
    
    log_success "AI engine vytvořen"
}

# Funkce pro vytvoření instalačních skriptů
create_installation_scripts() {
    log_step "Vytvářím pokročilé instalační skripty..."
    
    local base_dir="$1"
    
    # Hlavní instalační skript pro Linux
    cat > "$base_dir/installers/linux/install_starko_linux.sh" << 'EOF'
#!/bin/bash

# =============================================
# STARKO WORKSPACE - LINUX INSTALÁTOR
# =============================================

set -e

# Barvy
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Proměnné
STARKO_DIR="$HOME/.config/StarkoMasterProfile"
VSCODE_DIR="$HOME/.config/Code/User"
BACKUP_DIR="$STARKO_DIR/backups"
INSTALL_LOG="$STARKO_DIR/install.log"

# Funkce pro logování
log() {
    echo -e "${CYAN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$INSTALL_LOG"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}" | tee -a "$INSTALL_LOG"
}

log_error() {
    echo -e "${RED}❌ $1${NC}" | tee -a "$INSTALL_LOG"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}" | tee -a "$INSTALL_LOG"
}

log_step() {
    echo -e "${BLUE}🎯 $1${NC}" | tee -a "$INSTALL_LOG"
}

# Kontrola závislostí
check_dependencies() {
    log_step "Kontrola závislostí..."
    
    local missing=()
    
    # Kontrola Python
    if ! command -v python3 &> /dev/null; then
        missing+=("Python3")
    fi
    
    # Kontrola pip
    if ! command -v pip3 &> /dev/null; then
        missing+=("pip3")
    fi
    
    # Kontrola VS Code
    if ! command -v code &> /dev/null; then
        log_warning "VS Code není v PATH. Některé funkce nemusí fungovat."
    fi
    
    if [ ${#missing[@]} -ne 0 ]; then
        log_error "Chybějící závislosti: ${missing[*]}"
        log "Instalace chybějících závislostí..."
        
        # Detekce distribuce
        if command -v apt &> /dev/null; then
            # Debian/Ubuntu
            sudo apt update
            for dep in "${missing[@]}"; do
                case $dep in
                    "Python3") sudo apt install -y python3 python3-pip;;
                    "pip3") sudo apt install -y python3-pip;;
                esac
            done
        elif command -v dnf &> /dev/null; then
            # Fedora
            sudo dnf update
            for dep in "${missing[@]}"; do
                case $dep in
                    "Python3") sudo dnf install -y python3 python3-pip;;
                    "pip3") sudo dnf install -y python3-pip;;
                esac
            done
        elif command -v pacman &> /dev/null; then
            # Arch
            sudo pacman -Sy
            for dep in "${missing[@]}"; do
                case $dep in
                    "Python3") sudo pacman -S --noconfirm python python-pip;;
                    "pip3") sudo pacman -S --noconfirm python-pip;;
                esac
            done
        else
            log_error "Nepodporovaná distribuce. Instalujte závislosti ručně."
            return 1
        fi
    fi
    
    log_success "Všechny závislosti jsou nainstalovány"
}

# Vytvoření adresářů
create_directories() {
    log_step "Vytváření adresářů..."
    
    mkdir -p "$STARKO_DIR"
    mkdir -p "$VSCODE_DIR/snippets"
    mkdir -p "$BACKUP_DIR"
    mkdir -p "$STARKO_DIR/themes"
    mkdir -p "$STARKO_DIR/icons"
    
    log_success "Adresáře vytvořeny"
}

# Záloha existující konfigurace
backup_existing_config() {
    log_step "Zálohování existující konfigurace..."
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_path="$BACKUP_DIR/$timestamp"
    
    mkdir -p "$backup_path"
    
    if [ -d "$VSCODE_DIR" ]; then
        cp "$VSCODE_DIR/settings.json" "$backup_path/" 2>/dev/null || true
        cp "$VSCODE_DIR/extensions.json" "$backup_path/" 2>/dev/null || true
        cp "$VSCODE_DIR/tasks.json" "$backup_path/" 2>/dev/null || true
        cp "$VSCODE_DIR/launch.json" "$backup_path/" 2>/dev/null || true
        
        if [ -d "$VSCODE_DIR/snippets" ]; then
            cp -r "$VSCODE_DIR/snippets" "$backup_path/" 2>/dev/null || true
        fi
    fi
    
    log_success "Záloha vytvořena: $backup_path"
}

# Instalace tématu
install_theme() {
    log_step "Instalace Starko Dark Pro tématu..."
    
    cp "../../themes/starko-dark-pro.json" "$VSCODE_DIR/"
    
    if [ $? -eq 0 ]; then
        log_success "Téma instalováno"
    else
        log_error "Chyba při instalaci tématu"
        return 1
    fi
}

# Instalace snippetů
install_snippets() {
    log_step "Instalace snippetů..."
    
    cp "../../snippets/"*.json "$VSCODE_DIR/snippets/"
    
    if [ $? -eq 0 ]; then
        log_success "Snippety instalovány"
    else
        log_error "Chyba při instalaci snippetů"
        return 1
    fi
}

# Instalace konfigurace VS Code
install_vscode_config() {
    log_step "Instalace VS Code konfigurace..."
    
    cp "../../.vscode/"*.json "$VSCODE_DIR/"
    
    if [ $? -eq 0 ]; then
        log_success "Konfigurace VS Code instalována"
    else
        log_error "Chyba při instalaci konfigurace"
        return 1
    fi
}

# Instalace ikon
install_icons() {
    log_step "Instalace ikon..."
    
    cp -r "../../icons/"* "$STARKO_DIR/icons/" 2>/dev/null || true
    
    log_success "Ikony instalovány"
}

# Kontrola instalace
verify_installation() {
    log_step "Kontrola instalace..."
    
    local errors=0
    
    # Kontrola souborů
    declare -a required_files=(
        "$VSCODE_DIR/settings.json"
        "$VSCODE_DIR/starko-dark-pro.json"
        "$VSCODE_DIR/snippets/python.json"
        "$VSCODE_DIR/snippets/bash.json"
    )
    
    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            log_error "Chybí soubor: $file"
            ((errors++))
        fi
    done
    
    if [ $errors -eq 0 ]; then
        log_success "Instalace úspěšně ověřena"
        return 0
    else
        log_error "Instalace obsahuje chyby: $errors chybějících souborů"
        return 1
    fi
}

# Oprava instalace
fix_installation() {
    log_step "Oprava instalace..."
    
    # Znovu spustit instalaci
    install_theme
    install_snippets
    install_vscode_config
    install_icons
    
    log_success "Oprava dokončena"
}

# Hlavní instalační funkce
main_installation() {
    echo -e "${PURPLE}"
    echo "============================================="
    echo "   STARKO WORKSPACE - LINUX INSTALACE"
    echo "============================================="
    echo -e "${NC}"
    
    log "Spouštím instalaci Starko Workspace..."
    
    # Vytvoření log souboru
    mkdir -p "$STARKO_DIR"
    > "$INSTALL_LOG"
    
    # Hlavní instalace
    check_dependencies
    create_directories
    backup_existing_config
    install_theme
    install_snippets
    install_vscode_config
    install_icons
    
    # Ověření
    if verify_installation; then
        echo
        echo -e "${GREEN}"
        echo "============================================="
        echo "       LINUX INSTALACE DOKONČENA!"
        echo "============================================="
        echo -e "${NC}"
        
        log_success "Starko Workspace byl úspěšně nainstalován"
        echo
        echo -e "${CYAN}Následující kroky:${NC}"
        echo "1. Restartujte VS Code"
        echo "2. Vyberte téma: Starko Dark Pro"
        echo "3. Nainstalujte doporučená rozšíření"
        echo "4. Spusťte Web GUI: ${GREEN}python web_gui/app.py${NC}"
        echo
        echo -e "${YELLOW}Instalační log: $INSTALL_LOG${NC}"
    else
        echo
        log_error "Instalace obsahuje chyby. Pokus o opravu..."
        fix_installation
        
        if verify_installation; then
            log_success "Oprava byla úspěšná"
        else
            log_error "Instalace selhala. Zkontrolujte log: $INSTALL_LOG"
            exit 1
        fi
    fi
}

# Zobrazení nápovědy
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Starko Workspace Linux Installer"
    echo ""
    echo "Options:"
    echo "  --fix          Opravit instalaci"
    echo "  --verify       Ověřit instalaci"
    echo "  --help         Zobrazit nápovědu"
    echo ""
    echo "Examples:"
    echo "  $0             # Kompletní instalace"
    echo "  $0 --fix       # Oprava instalace"
    echo "  $0 --verify    # Ověření instalace"
}

# Zpracování argumentů
case "${1:-}" in
    "--fix")
        fix_installation
        ;;
    "--verify")
        verify_installation
        ;;
    "--help")
        show_help
        ;;
    *)
        main_installation
        ;;
esac
EOF

    chmod +x "$base_dir/installers/linux/install_starko_linux.sh"

    # Hlavní instalační skript pro Windows
    cat > "$base_dir/installers/windows/install_starko_windows.ps1" << 'EOF'
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
EOF

    log_success "Pokročilé instalační skripty vytvořeny"
}

# Funkce pro vytvoření dalších komponent
create_additional_components() {
    log_step "Vytvářím další komponenty..."
    
    local base_dir="$1"
    
    # requirements.txt
    cat > "$base_dir/requirements.txt" << 'EOF'
# =============================================
# STARKO RPI5 AI WORKSPACE - ZÁVISLOSTI
# =============================================

# 🤖 AI a strojové učení
torch>=2.0.1
tensorflow>=2.13.0
scikit-learn>=1.3.0
transformers>=4.30.2
sentence-transformers>=2.2.2

# 🌐 Web a GUI
flask>=2.3.3
flask-cors>=4.0.0
dash>=2.14.1
plotly>=5.17.0

# 📊 Data a utility
numpy>=1.24.3
pandas>=2.0.3
requests>=2.31.0
pyyaml>=6.0.1

# 🔐 Bezpečnost
cryptography>=41.0.4
python-dotenv>=1.0.0

# 📝 Logování
psutil>=5.9.5
loguru>=0.7.2

# 🧪 Testování
pytest>=7.4.0
pylint>=2.17.4
black>=23.7.0

# 🍓 Raspberry Pi
RPi.GPIO>=0.7.1
gpiozero>=2.0
picamera2>=0.3.7

# 🔄 GitHub
PyGithub>=1.59.0
gitpython>=3.1.31

# 🎯 Simulace
fake-rpi>=0.8.1
EOF

    # README.md
    cat > "$base_dir/README.md" << EOF
# 🍓 Starko RPi5 AI Workspace

**Kompletní vývojové prostředí pro Raspberry Pi 5 s AI integrací a Starko profilem**

## 🚀 Rychlý Start

\`\`\`bash
# Aktivujte virtuální prostředí
source venv/bin/activate

# Spusťte Web GUI
python web_gui/app.py

# Vytvořte první projekt
python projects/project_manager.py create --name muj_projekt
\`\`\`

## 📁 Struktura

\`\`\`
$WORKSPACE_NAME/
├── 🎨 themes/              # Starko Dark Pro téma
├── 📝 snippets/            # Code snippets
├── 🤖 ai_engine/           # Lokální AI systém
├── 🚀 projects/            # Správa projektů  
├── 🌐 web_gui/             # Moderní Web GUI
├── 🔧 scripts/             # Automatizační nástroje
├── ⚙️ config/              # Konfigurace
├── 🧪 tests/               # Testovací framework
├── 📚 docs/                # Dokumentace
├── 🔗 github/              # GitHub integrace
├── 🛠️ installers/          # Instalační skripty
└── 🎯 .vscode/             # VS Code nastavení
\`\`\`

## 🌟 Hlavní Funkce

### 🎨 **Starko Dark Pro Téma**
- Profesionální tmavé téma pro VS Code
- Optimalizované pro vývoj AI aplikací
- Vlastní ikony a snippet pack

### 🤖 **AI Engine**
- Lokální AI s učením z kódu
- Generování kódu na základě promptů
- Systém paměti a pattern recognition

### 🌐 **Moderní Web GUI**
- Dashboard s monitoringem systému
- Správa projektů přes webové rozhraní
- AI generátor kódu
- Instalace VS Code rozšíření

### 🛠️ **Pokročilé Instalátory**
- **Linux**: Kompletní instalace s kontrolou závislostí
- **Windows**: PowerShell skript s opravami
- **Interaktivní menu**: Vizualizace průběhu instalace

### 🔒 **Bezpečnostní Funkce**
- Šifrované ukládání API klíčů
- Automatické zálohování konfigurace
- Kontrola integrity instalace

## 🔧 Instalace

### Linux
\`\`\`bash
cd installers/linux
./install_starko_linux.sh
\`\`\`

### Windows
\`\`\`powershell
cd installers\windows
.\install_starko_windows.ps1
\`\`\`

### Interaktivní Instalace
\`\`\`bash
./install_starko_workspace.sh
\`\`\`

## 📖 Dokumentace

- [Web GUI](http://localhost:8080) - Spusťte \`python web_gui/app.py\`
- [AI Použití](docs/ai_usage_guide.md)
- [Instalace](docs/installation_guide.md)

## 🎯 Doporučená Rozšíření VS Code

Spusťte v Web GUI: *"Instalovat VS Code rozšíření"* nebo:

\`\`\`bash
code --install-extension ms-python.python
code --install-extension GitHub.copilot
# ... a další z extensions.json
\`\`\`

---

**Starko Master Workspace 2025**  
Optimalizováno pro Raspberry Pi 5, AI vývoj a produktivitu

*Vygenerováno: $(date)*
EOF

    # Vytvoření základního projektu
    cat > "$base_dir/projects/project_manager.py" << 'EOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
SPRÁVCE PROJEKTŮ STARKO WORKSPACE
"""

import os
import json
import argparse
from pathlib import Path
from datetime import datetime

class StarkoProjectManager:
    def __init__(self, workspace_root: str = "."):
        self.workspace_root = Path(workspace_root)
        self.projects_dir = self.workspace_root / "projects"
        
    def create_project(self, project_name: str, project_type: str = "standard"):
        """Vytvoří nový projekt s Starko šablonou"""
        project_path = self.projects_dir / project_name
        
        if project_path.exists():
            print(f"❌ Projekt '{project_name}' již existuje!")
            return False
        
        try:
            # Vytvoření struktury
            (project_path / "src").mkdir(parents=True)
            (project_path / "tests").mkdir()
            (project_path / "docs").mkdir()
            (project_path / "config").mkdir()
            (project_path / "data").mkdir()
            
            # Hlavní soubor
            main_content = f'''#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
PROJEKT: {project_name}
TYP: {project_type}
STARKO WORKSPACE - {datetime.now().year}
"""

import os
import sys
from pathlib import Path

def main():
    """Hlavní funkce projektu"""
    print("🚀 Vítejte v projektu {project_name}!")
    print(f"📍 Cesta: {project_path}")
    print(f"🎯 Typ: {project_type}")
    
    # TODO: Implementujte svůj kód zde
    
    print("✅ Projekt úspěšně spuštěn!")

if __name__ == "__main__":
    main()
'''
            
            with open(project_path / "src" / "main.py", "w") as f:
                f.write(main_content)
            
            # Konfigurace projektu
            config = {
                "project_name": project_name,
                "type": project_type,
                "version": "1.0.0",
                "created": datetime.now().isoformat(),
                "starko_template": True,
                "author": "Starko Master"
            }
            
            with open(project_path / "config" / "project.json", "w") as f:
                json.dump(config, f, indent=2)
            
            # README
            readme_content = f'''# {project_name}

Projekt vytvořený pomocí Starko Workspace.

## Spuštění

\`\`\`bash
python src/main.py
\`\`\`

## Struktura

- `src/` - Zdrojové kódy
- `tests/` - Testy
- `docs/` - Dokumentace
- `config/` - Konfigurace
- `data/` - Data projektu

---
*Vytvořeno: {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}*
'''
            
            with open(project_path / "README.md", "w") as f:
                f.write(readme_content)
            
            print(f"✅ Projekt '{project_name}' vytvořen!")
            print(f"📍 Cesta: {project_path}")
            return True
            
        except Exception as e:
            print(f"❌ Chyba při vytváření projektu: {e}")
            return False

def main():
    parser = argparse.ArgumentParser(description="Správce projektů Starko Workspace")
    parser.add_argument("action", choices=["create", "list", "info"])
    parser.add_argument("--name", help="Název projektu")
    parser.add_argument("--type", default="standard", help="Typ projektu")
    
    args = parser.parse_args()
    manager = StarkoProjectManager()
    
    if args.action == "create":
        if not args.name:
            print("❌ Zadejte název projektu: --name NAZEV")
            return
        manager.create_project(args.name, args.type)
    elif args.action == "list":
        print("📂 Seznam projektů:")
        projects_dir = Path("projects")
        if projects_dir.exists():
            for project in projects_dir.iterdir():
                if project.is_dir():
                    print(f"  - {project.name}")
    elif args.action == "info":
        print("🤖 Starko Project Manager")
        print("Použití: python projects/project_manager.py create --name NAZEV")

if __name__ == "__main__":
    main()
EOF

    chmod +x "$base_dir/projects/project_manager.py"
    
    log_success "Další komponenty vytvořeny"
}

# Hlavní funkce
main() {
    log_info "Spouštím generátor Starko RPi5 AI Workspace..."
    log_info "Název workspace: $WORKSPACE_NAME"
    log_info "Přepsat existující: $OVERWRITE"
    log_info "Vytvořit virtuální prostředí: $CREATE_VENV"
    log_info "Instalovat závislosti: $INSTALL_DEPS"
    log_info "Typ instalace: $INSTALL_TYPE"
    
    echo ""
    
    # Kontroly
    check_dependencies
    check_existing_workspace "$WORKSPACE_NAME"
    
    # Vytváření struktury
    create_directory_structure "$WORKSPACE_NAME"
    create_starko_theme "$WORKSPACE_NAME"
    create_vscode_config "$WORKSPACE_NAME"
    create_interactive_installer "$WORKSPACE_NAME"
    create_enhanced_web_gui "$WORKSPACE_NAME"
    create_ai_engine "$WORKSPACE_NAME"
    create_installation_scripts "$WORKSPACE_NAME"
    create_additional_components "$WORKSPACE_NAME"
    
    # Finální zpráva
    echo ""
    log_success "🎉 STARKO RPI5 AI WORKSPACE VERZE 3.0 ÚSPĚŠNĚ VYTVOŘEN!"
    echo ""
    log_info "📍 Cesta: $(pwd)/$WORKSPACE_NAME"
    echo ""
    log_info "🚀 INSTALACE STARKO PROFILU:"
    echo ""
    log_info "📝 LINUX:"
    echo "   cd $WORKSPACE_NAME/installers/linux"
    echo "   ./install_starko_linux.sh"
    echo ""
    log_info "🪟 WINDOWS:"
    echo "   cd $WORKSPACE_NAME\\installers\\windows"
    echo "   .\\install_starko_windows.ps1"
    echo ""
    log_info "🎮 INTERAKTIVNÍ INSTALACE:"
    echo "   cd $WORKSPACE_NAME"
    echo "   ./install_starko_workspace.sh"
    echo ""
    log_info "🌐 SPUŠTĚNÍ WEB GUI:"
    echo "   cd $WORKSPACE_NAME"
    echo "   python web_gui/app.py"
    echo ""
    log_info "📊 PŘÍSTUP K DASHBOARDU:"
    echo "   Otevřete: http://localhost:8080"
    echo ""
    log_info "🤖 VYTVOŘENÍ PRVNÍHO PROJEKTU:"
    echo "   python projects/project_manager.py create --name muj-projekt"
    echo ""
    log_info "🔧 DOPORUČENÁ ROZŠÍŘENÍ VS CODE:"
    echo "   Otevřete Web GUI a klikněte na 'Instalovat Rozšíření'"
    echo ""
    log_info "🎯 Jste připraveni začít vytvářet úžasné AI projekty se Starko profilem!"
    echo ""
    log_info "📖 Dokumentace: $WORKSPACE_NAME/README.md"
}

# Spuštění hlavní funkce
main
