#!/bin/bash

# =============================================
# STARKO AI WORKSPACE - AKTUALIZAČNÍ SKRIPT 4.0
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

log_step() {
    echo -e "${CYAN}🎯 KROK:${NC} $1"
}

# Proměnné
CURRENT_DIR=$(pwd)
BACKUP_DIR="$CURRENT_DIR/backup_$(date +%Y%m%d_%H%M%S)"
SELECTED_PROFILE="full"

# Seznam dostupných profilů
declare -A PROFILES=(
    ["minimal"]="Minimální (základní nástroje)"
    ["python"]="Python vývoj" 
    ["ai-ml"]="AI a strojové učení"
    ["web"]="Webový vývoj"
    ["iot"]="IoT a Raspberry Pi"
    ["game"]="Vývoj her"
    ["full"]="Kompletní (všechny nástroje)"
)

# Funkce pro kontrolu existence workspace
check_workspace_exists() {
    log_step "Kontroluji existenci workspace..."
    
    local required_dirs=(".vscode" "ai_engine" "projects" "web_gui" "scripts")
    local missing_dirs=()
    
    for dir in "${required_dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            missing_dirs+=("$dir")
        fi
    done
    
    if [ ${#missing_dirs[@]} -ne 0 ]; then
        log_error "Chybí důležité adresáře: ${missing_dirs[*]}"
        log_error "Spusťte skript v kořenovém adresáři Starko workspace!"
        exit 1
    fi
    
    log_success "Workspace nalezen a validní"
}

# Funkce pro vytvoření zálohy
create_backup() {
    log_step "Vytvářím zálohu současného workspace..."
    
    mkdir -p "$BACKUP_DIR"
    
    # Záloha důležitých souborů
    local backup_files=(
        ".vscode/settings.json"
        ".vscode/extensions.json" 
        ".vscode/tasks.json"
        ".vscode/launch.json"
        "config/api_config.json"
        "config/workspace_config.json"
        "projects/project_manager.py"
        "web_gui/app.py"
    )
    
    local backup_dirs=(
        "ai_engine"
        "projects"
        "config"
        "scripts"
    )
    
    for file in "${backup_files[@]}"; do
        if [ -f "$file" ]; then
            cp --parents "$file" "$BACKUP_DIR/" 2>/dev/null || true
        fi
    done
    
    for dir in "${backup_dirs[@]}"; do
        if [ -d "$dir" ]; then
            cp -r "$dir" "$BACKUP_DIR/" 2>/dev/null || true
        fi
    done
    
    log_success "Záloha vytvořena: $BACKUP_DIR"
}

# Funkce pro vytvoření nových adresářů
create_new_directories() {
    log_step "Vytvářím novou adresářovou strukturu..."
    
    local new_dirs=(
        "themes"
        "profiles"
        "profiles/minimal"
        "profiles/python"
        "profiles/ai-ml" 
        "profiles/web"
        "profiles/iot"
        "profiles/game"
        "profiles/full"
        "icons"
    )
    
    for dir in "${new_dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            log_debug "Vytvořen adresář: $dir"
        fi
    done
    
    log_success "Nová adresářová struktura vytvořena"
}

# Funkce pro aktualizaci VS Code konfigurace
update_vscode_config() {
    log_step "Aktualizuji VS Code konfiguraci..."
    
    # Aktualizace settings.json
    if [ -f ".vscode/settings.json" ]; then
        cp ".vscode/settings.json" ".vscode/settings.json.backup"
    fi
    
    cat > ".vscode/settings.json" << 'EOF'
{
    "workbench.colorTheme": "Starko Dark Pro",
    "workbench.iconTheme": "material-icon-theme",
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
    
    "starko.profile": "full",
    "starko.version": "4.0.0",
    
    "rpi.autoDeploy": true,
    "rpi.simulationMode": true
}
EOF

    # Aktualizace extensions.json
    cat > ".vscode/extensions.json" << 'EOF'
{
    "recommendations": [
        "ms-python.python",
        "ms-python.vscode-pylance",
        "ms-python.black-formatter",
        "ms-python.flake8",
        "ms-python.mypy-type-checker",
        "ms-toolsai.jupyter",
        "ms-toolsai.vscode-jupyter-cell-tags",
        "GitHub.copilot",
        "GitHub.copilot-chat",
        "codeium.codeium",
        "ms-vscode.remote-ssh",
        "ms-vscode.remote-ssh-edit",
        "ms-vscode.makefile-tools",
        "ms-vscode.cmake-tools",
        "bradlc.vscode-tailwindcss",
        "ms-vscode.live-server",
        "eamodio.gitlens",
        "ms-azuretools.vscode-docker",
        "ms-vscode-remote.remote-containers",
        "pkief.material-icon-theme",
        "ms-vscode.vscode-fluent-icons",
        "gruntfuggly.todo-tree",
        "usernamehw.errorlens"
    ]
}
EOF

    log_success "VS Code konfigurace aktualizována"
}

# Funkce pro vytvoření Starko tématu
create_starko_theme() {
    log_step "Vytvářím Starko Dark Pro téma..."
    
    cat > "themes/starko-dark-pro.json" << 'EOF'
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

    log_success "Starko Dark Pro téma vytvořeno"
}

# Funkce pro vytvoření systémů profilů
create_profile_system() {
    log_step "Vytvářím systém profilů..."
    
    # Hlavní konfigurace profilů
    cat > "profiles/profiles.json" << 'EOF'
{
    "version": "1.0.0",
    "active_profile": "full",
    "profiles": {
        "minimal": {
            "name": "Minimální",
            "description": "Základní nástroje pro rychlý start",
            "extensions": [
                "ms-python.python",
                "ms-python.vscode-pylance",
                "eamodio.gitlens"
            ],
            "settings": {
                "python.defaultInterpreterPath": "${workspaceFolder}/venv/bin/python",
                "files.autoSave": "afterDelay"
            }
        },
        "python": {
            "name": "Python vývoj",
            "description": "Kompletní prostředí pro Python vývoj",
            "extensions": [
                "ms-python.python",
                "ms-python.vscode-pylance",
                "ms-python.black-formatter",
                "ms-python.flake8",
                "ms-python.mypy-type-checker",
                "eamodio.gitlens",
                "ms-vscode.makefile-tools"
            ],
            "settings": {
                "python.defaultInterpreterPath": "${workspaceFolder}/venv/bin/python",
                "python.analysis.typeCheckingMode": "basic",
                "python.formatting.provider": "black"
            }
        },
        "ai-ml": {
            "name": "AI a strojové učení",
            "description": "Specializované pro AI a ML projekty",
            "extensions": [
                "ms-python.python",
                "ms-python.vscode-pylance",
                "ms-toolsai.jupyter",
                "ms-toolsai.vscode-jupyter-cell-tags",
                "ms-toolsai.jupyter-renderers",
                "GitHub.copilot",
                "GitHub.copilot-chat",
                "ms-python.black-formatter"
            ],
            "settings": {
                "python.defaultInterpreterPath": "${workspaceFolder}/venv/bin/python",
                "jupyter.notebookFileRoot": "${workspaceFolder}",
                "ai.enabled": true
            }
        },
        "web": {
            "name": "Webový vývoj",
            "description": "Moderní webový vývoj",
            "extensions": [
                "ms-python.python",
                "bradlc.vscode-tailwindcss",
                "ms-vscode.live-server",
                "ritwickdey.liveserver",
                "ecmel.vscode-html-css",
                "esbenp.prettier-vscode",
                "ms-vscode.vscode-typescript-next"
            ],
            "settings": {
                "liveServer.settings.donotShowInfoMsg": true,
                "emmet.triggerExpansionOnTab": true
            }
        },
        "iot": {
            "name": "IoT a Raspberry Pi",
            "description": "Vývoj pro IoT a Raspberry Pi",
            "extensions": [
                "ms-python.python",
                "ms-vscode.remote-ssh",
                "ms-vscode.remote-ssh-edit",
                "ms-vscode.makefile-tools",
                "ms-vscode.cmake-tools",
                "dan-c-underwood.arm",
                "ms-vscode.vscode-serial-monitor"
            ],
            "settings": {
                "python.defaultInterpreterPath": "${workspaceFolder}/venv/bin/python",
                "rpi.autoDeploy": true,
                "rpi.simulationMode": true
            }
        },
        "game": {
            "name": "Vývoj her",
            "description": "Pro vývoj her a grafiky",
            "extensions": [
                "ms-python.python",
                "ms-vscode.cmake-tools",
                "ms-vscode.makefile-tools",
                "unity.unity-debug",
                "ms-dotnettools.csharp",
                "dart-code.flutter",
                "nash.awesome-flutter-snippets"
            ],
            "settings": {
                "python.defaultInterpreterPath": "${workspaceFolder}/venv/bin/python",
                "cmake.configureOnOpen": true
            }
        },
        "full": {
            "name": "Kompletní",
            "description": "Všechny nástroje a rozšíření",
            "extensions": [
                "ms-python.python",
                "ms-python.vscode-pylance",
                "ms-python.black-formatter",
                "ms-python.flake8",
                "ms-python.mypy-type-checker",
                "ms-toolsai.jupyter",
                "ms-toolsai.vscode-jupyter-cell-tags",
                "GitHub.copilot",
                "GitHub.copilot-chat",
                "codeium.codeium",
                "ms-vscode.remote-ssh",
                "ms-vscode.remote-ssh-edit",
                "ms-vscode.makefile-tools",
                "ms-vscode.cmake-tools",
                "bradlc.vscode-tailwindcss",
                "ms-vscode.live-server",
                "eamodio.gitlens",
                "ms-azuretools.vscode-docker",
                "ms-vscode-remote.remote-containers",
                "pkief.material-icon-theme",
                "ms-vscode.vscode-fluent-icons",
                "gruntfuggly.todo-tree",
                "usernamehw.errorlens"
            ],
            "settings": {
                "python.defaultInterpreterPath": "${workspaceFolder}/venv/bin/python",
                "workbench.colorTheme": "Starko Dark Pro",
                "workbench.iconTheme": "material-icon-theme",
                "ai.enabled": true,
                "rpi.autoDeploy": true
            }
        }
    }
}
EOF

    # Vytvoření profilových konfigurací
    for profile in "${!PROFILES[@]}"; do
        cat > "profiles/$profile/profile-info.json" << EOF
{
    "id": "$profile",
    "name": "${PROFILES[$profile]}",
    "description": "Profil ${PROFILES[$profile]}",
    "version": "1.0.0",
    "created": "$(date -Iseconds)",
    "compatibility": ["linux", "windows", "macos"]
}
EOF
    done

    log_success "Systém profilů vytvořen"
}

# Funkce pro vytvoření správce profilů
create_profile_manager() {
    log_step "Vytvářím správce profilů..."
    
    cat > "scripts/profile_manager.py" << 'EOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
SPRÁVCE PROFILŮ STARKO AI WORKSPACE
"""

import json
import os
import shutil
import argparse
from pathlib import Path
import subprocess

class ProfileManager:
    def __init__(self, workspace_root: str = "."):
        self.workspace_root = Path(workspace_root)
        self.profiles_file = self.workspace_root / "profiles" / "profiles.json"
        self.vscode_dir = self.workspace_root / ".vscode"
        self.load_profiles()
    
    def load_profiles(self):
        """Načte konfiguraci profilů"""
        with open(self.profiles_file, 'r') as f:
            self.profiles_data = json.load(f)
    
    def save_profiles(self):
        """Uloží konfiguraci profilů"""
        with open(self.profiles_file, 'w') as f:
            json.dump(self.profiles_data, f, indent=2)
    
    def list_profiles(self):
        """Zobrazí seznam dostupných profilů"""
        print("🎯 DOSTUPNÉ PROFILY STARKO AI WORKSPACE:")
        print("=" * 50)
        
        for profile_id, profile_data in self.profiles_data['profiles'].items():
            active_indicator = " ✅" if profile_id == self.profiles_data['active_profile'] else ""
            print(f"  {profile_id:<12} - {profile_data['name']}{active_indicator}")
            print(f"     {profile_data['description']}")
            print(f"     Rozšíření: {len(profile_data['extensions'])}")
            print()
    
    def switch_profile(self, profile_id: str, install_extensions: bool = True):
        """Přepne na zvolený profil"""
        if profile_id not in self.profiles_data['profiles']:
            print(f"❌ Profil '{profile_id}' neexistuje!")
            return False
        
        profile = self.profiles_data['profiles'][profile_id]
        
        print(f"🔄 Přepínám na profil: {profile['name']}")
        
        # Aktualizace aktivního profilu
        self.profiles_data['active_profile'] = profile_id
        self.save_profiles()
        
        # Aktualizace VS Code settings
        self.update_vscode_settings(profile)
        
        # Instalace rozšíření
        if install_extensions:
            self.install_profile_extensions(profile)
        
        print(f"✅ Profil '{profile['name']}' byl aktivován!")
        return True
    
    def update_vscode_settings(self, profile):
        """Aktualizuje VS Code nastavení podle profilu"""
        settings_file = self.vscode_dir / "settings.json"
        
        if not settings_file.exists():
            print("❌ Soubor settings.json neexistuje!")
            return
        
        with open(settings_file, 'r') as f:
            settings = json.load(f)
        
        # Aktualizace nastavení z profilu
        if 'settings' in profile:
            settings.update(profile['settings'])
        
        # Přidání starko specifických nastavení
        settings['starko.profile'] = self.profiles_data['active_profile']
        settings['starko.version'] = '4.0.0'
        
        with open(settings_file, 'w') as f:
            json.dump(settings, f, indent=2)
        
        print("✅ VS Code nastavení aktualizováno")
    
    def install_profile_extensions(self, profile):
        """Nainstaluje rozšíření pro profil"""
        if 'extensions' not in profile or not profile['extensions']:
            print("ℹ️  Žádná rozšíření k instalaci")
            return
        
        print(f"📦 Instaluji {len(profile['extensions'])} rozšíření...")
        
        installed = 0
        failed = 0
        
        for extension in profile['extensions']:
            try:
                result = subprocess.run([
                    'code', '--install-extension', extension
                ], capture_output=True, text=True, timeout=120)
                
                if result.returncode == 0:
                    print(f"   ✅ {extension}")
                    installed += 1
                else:
                    print(f"   ❌ {extension}")
                    failed += 1
                    
            except subprocess.TimeoutExpired:
                print(f"   ⏰ {extension} (timeout)")
                failed += 1
            except Exception as e:
                print(f"   ❌ {extension} ({e})")
                failed += 1
        
        print(f"📊 Výsledek: {installed} úspěšných, {failed} chyb")
    
    def create_custom_profile(self, profile_id: str, name: str, description: str, 
                            extensions: list, settings: dict):
        """Vytvoří vlastní profil"""
        if profile_id in self.profiles_data['profiles']:
            print(f"❌ Profil '{profile_id}' již existuje!")
            return False
        
        self.profiles_data['profiles'][profile_id] = {
            'name': name,
            'description': description,
            'extensions': extensions,
            'settings': settings
        }
        
        self.save_profiles()
        print(f"✅ Vlastní profil '{name}' vytvořen!")
        return True
    
    def get_active_profile(self):
        """Získá aktivní profil"""
        active_id = self.profiles_data['active_profile']
        return active_id, self.profiles_data['profiles'][active_id]

def main():
    parser = argparse.ArgumentParser(description="Správce profilů Starko AI Workspace")
    parser.add_argument("action", nargs="?", choices=["list", "switch", "active", "create"], help="Akce")
    parser.add_argument("--profile", help="ID profilu pro přepnutí")
    parser.add_argument("--name", help="Název vlastního profilu")
    parser.add_argument("--description", help="Popis vlastního profilu")
    parser.add_argument("--no-extensions", action="store_true", help="Neinstalovat rozšíření")
    
    args = parser.parse_args()
    manager = ProfileManager()
    
    try:
        if args.action == "list":
            manager.list_profiles()
        elif args.action == "switch":
            if not args.profile:
                print("❌ Zadejte --profile PROFILE_ID")
                return
            manager.switch_profile(args.profile, not args.no_extensions)
        elif args.action == "active":
            active_id, profile = manager.get_active_profile()
            print(f"✅ Aktivní profil: {profile['name']} ({active_id})")
        elif args.action == "create":
            if not all([args.profile, args.name, args.description]):
                print("❌ Pro vytvoření profilu zadejte --profile, --name a --description")
                return
            # Pro zjednodušení použijeme rozšíření z full profilu
            base_profile = manager.profiles_data['profiles']['full']
            manager.create_custom_profile(
                args.profile, args.name, args.description,
                base_profile['extensions'], base_profile['settings']
            )
        else:
            manager.list_profiles()
            print("\nPříklady použití:")
            print("  python scripts/profile_manager.py list")
            print("  python scripts/profile_manager.py switch --profile python")
            print("  python scripts/profile_manager.py active")
            
    except Exception as e:
        print(f"❌ Chyba: {e}")

if __name__ == "__main__":
    main()
EOF

    chmod +x "scripts/profile_manager.py"
    log_success "Správce profilů vytvořen"
}

# Funkce pro aktualizaci Web GUI
update_web_gui() {
    log_step "Aktualizuji Web GUI..."
    
    # Záloha původního app.py
    if [ -f "web_gui/app.py" ]; then
        cp "web_gui/app.py" "web_gui/app.py.backup"
    fi
    
    # Vytvoření aktualizovaného Web GUI
    cat > "web_gui/app.py" << 'EOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
STARKO AI WORKSPACE - AKTUALIZOVANÉ WEB GUI S PROFILY
"""

from flask import Flask, render_template, jsonify, request
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
import sys

# Přidání cesty k scripts pro import profile_manager
sys.path.append(str(Path(__file__).parent.parent / "scripts"))
try:
    from profile_manager import ProfileManager
    PROFILE_MANAGER_AVAILABLE = True
except ImportError:
    PROFILE_MANAGER_AVAILABLE = False
    print("⚠️  ProfileManager není dostupný - profily budou omezené")

app = Flask(__name__, template_folder="templates", static_folder="static")
CORS(app)

# Konfigurace
WORKSPACE_DIR = Path(__file__).parent.parent
CONFIG_DIR = WORKSPACE_DIR / "config"

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class StarkoWorkspaceManager:
    def __init__(self):
        self.workspace_dir = WORKSPACE_DIR
        if PROFILE_MANAGER_AVAILABLE:
            self.profile_manager = ProfileManager(str(WORKSPACE_DIR))
        else:
            self.profile_manager = None
        self.setup_database()
    
    def setup_database(self):
        """Nastaví SQLite databázi pro správu workspace"""
        db_path = self.workspace_dir / "system" / "workspace.db"
        db_path.parent.mkdir(parents=True, exist_ok=True)
        
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS profile_history (
                id INTEGER PRIMARY KEY,
                timestamp TEXT,
                from_profile TEXT,
                to_profile TEXT,
                success BOOLEAN
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
            
            # Workspace statistiky
            workspace_stats = self.get_workspace_stats()
            
            # Informace o profilu
            profile_info = self.get_profile_info()
            
            return {
                "system": system_info,
                "performance": performance,
                "workspace": workspace_stats,
                "profile": profile_info,
                "timestamp": datetime.now().isoformat()
            }
        except Exception as e:
            logger.error(f"Chyba při získávání systémových informací: {e}")
            return {}
    
    def get_workspace_stats(self):
        """Získá statistiky workspace"""
        try:
            stats = {
                "total_projects": 0,
                "total_files": 0,
                "total_size": 0,
                "ai_models": 0,
                "scripts": 0,
                "profiles_count": 0
            }
            
            # Projekty
            projects_dir = self.workspace_dir / "projects"
            if projects_dir.exists():
                stats["total_projects"] = len([f for f in projects_dir.iterdir() if f.is_dir()])
            
            # Profily
            profiles_dir = self.workspace_dir / "profiles"
            if profiles_dir.exists():
                stats["profiles_count"] = len([f for f in profiles_dir.iterdir() if f.is_dir() and f.name != "__pycache__"])
            
            # Celkový počet souborů a velikost
            for file_path in self.workspace_dir.rglob('*'):
                if file_path.is_file():
                    stats["total_files"] += 1
                    stats["total_size"] += file_path.stat().st_size
            
            # Převod velikosti na MB
            stats["total_size_mb"] = round(stats["total_size"] / (1024 * 1024), 2)
            
            return stats
        except Exception as e:
            logger.error(f"Chyba při získávání statistik workspace: {e}")
            return {}
    
    def get_profile_info(self):
        """Získá informace o aktuálním profilu"""
        try:
            if not self.profile_manager:
                return {
                    "active": "unknown",
                    "name": "Profile Manager Not Available",
                    "description": "Profile system is not properly installed",
                    "extensions_count": 0,
                    "all_profiles": []
                }
            
            active_id, profile = self.profile_manager.get_active_profile()
            
            return {
                "active": active_id,
                "name": profile["name"],
                "description": profile["description"],
                "extensions_count": len(profile.get("extensions", [])),
                "all_profiles": list(self.profile_manager.profiles_data["profiles"].keys())
            }
        except Exception as e:
            logger.error(f"Chyba při získávání informací o profilu: {e}")
            return {}
    
    def switch_profile(self, profile_id):
        """Přepne profil"""
        try:
            if not self.profile_manager:
                return False
            
            success = self.profile_manager.switch_profile(profile_id)
            
            # Záznam do historie
            if success:
                conn = sqlite3.connect(self.workspace_dir / "system" / "workspace.db")
                cursor = conn.cursor()
                active_id, _ = self.profile_manager.get_active_profile()
                
                cursor.execute(
                    "INSERT INTO profile_history (timestamp, from_profile, to_profile, success) VALUES (?, ?, ?, ?)",
                    (datetime.now().isoformat(), active_id, profile_id, True)
                )
                conn.commit()
                conn.close()
            
            return success
        except Exception as e:
            logger.error(f"Chyba při přepínání profilu: {e}")
            return False

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

@app.route('/api/profiles', methods=['GET', 'POST'])
def handle_profiles():
    """API pro správu profilů"""
    if request.method == 'GET':
        if not workspace_manager.profile_manager:
            return jsonify([])
        
        profiles = workspace_manager.profile_manager.profiles_data["profiles"]
        active_id = workspace_manager.profile_manager.profiles_data["active_profile"]
        
        profiles_list = []
        for profile_id, profile_data in profiles.items():
            profiles_list.append({
                "id": profile_id,
                "name": profile_data["name"],
                "description": profile_data["description"],
                "extensions_count": len(profile_data.get("extensions", [])),
                "is_active": profile_id == active_id
            })
        
        return jsonify(profiles_list)
    
    elif request.method == 'POST':
        data = request.get_json()
        profile_id = data.get('profile_id')
        
        if not profile_id:
            return jsonify({"status": "error", "message": "Chybí profile_id"})
        
        success = workspace_manager.switch_profile(profile_id)
        
        if success:
            return jsonify({"status": "success", "message": f"Profil přepnut na {profile_id}"})
        else:
            return jsonify({"status": "error", "message": "Chyba při přepínání profilu"})

@app.route('/api/profiles/active')
def active_profile():
    """Aktivní profil"""
    profile_info = workspace_manager.get_profile_info()
    return jsonify({
        "id": profile_info["active"],
        "name": profile_info["name"],
        "description": profile_info["description"]
    })

@app.route('/api/profiles/<profile_id>/extensions')
def profile_extensions(profile_id):
    """Rozšíření pro konkrétní profil"""
    if not workspace_manager.profile_manager:
        return jsonify({"status": "error", "message": "Profile manager není dostupný"})
    
    profiles = workspace_manager.profile_manager.profiles_data["profiles"]
    
    if profile_id not in profiles:
        return jsonify({"status": "error", "message": "Profil neexistuje"})
    
    extensions = profiles[profile_id].get("extensions", [])
    return jsonify(extensions)

@app.route('/api/ai/generate-code', methods=['POST'])
def generate_code():
    """Generování kódu pomocí AI"""
    try:
        data = request.get_json()
        prompt = data.get('prompt', '')
        
        if not prompt:
            return jsonify({"status": "error", "message": "Prompt je povinný"})
        
        # Zde by byla integrace s AI API
        generated_code = f'''# AI GENEROVANÝ KÓD - STARKO AI WORKSPACE 4.0
# Prompt: {prompt}
# Generováno: {datetime.now().isoformat()}
# Profil: {workspace_manager.get_profile_info()['active']}

def ai_generated_function():
    """Funkce generovaná AI na základě vašeho promptu"""
    print("🎯 Tento kód byl generován Starko AI Workspace")
    print(f"Prompt: {prompt}")
    
    # TODO: Implementujte funkcionalitu podle promptu
    
    return "AI Generation Complete"

if __name__ == "__main__":
    result = ai_generated_function()
    print(f"✅ Výsledek: {result}")
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

    log_success "Web GUI aktualizován"
}

# Funkce pro aktualizaci dashboard template
update_dashboard_template() {
    log_step "Aktualizuji dashboard template..."
    
    # Záloha původního template
    if [ -f "web_gui/templates/dashboard.html" ]; then
        cp "web_gui/templates/dashboard.html" "web_gui/templates/dashboard.html.backup"
    fi
    
    # Vytvoření zjednodušeného aktualizovaného dashboardu
    mkdir -p "web_gui/templates"
    
    cat > "web_gui/templates/dashboard.html" << 'EOF'
<!DOCTYPE html>
<html lang="cs">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Starko AI Workspace 4.0 - Dashboard</title>
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
            padding: 20px;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        
        .header {
            background: rgba(26, 29, 34, 0.8);
            backdrop-filter: blur(20px);
            border-radius: 20px;
            padding: 30px;
            margin-bottom: 25px;
            border: 1px solid var(--starko-lighter);
            text-align: center;
        }
        
        .header h1 {
            font-size: 2.5em;
            background: linear-gradient(135deg, var(--starko-primary), var(--starko-accent));
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            margin-bottom: 10px;
        }
        
        .header .subtitle {
            color: var(--starko-text-secondary);
            font-size: 1.2em;
            margin-bottom: 15px;
        }
        
        .update-badge {
            display: inline-block;
            background: var(--starko-success);
            color: white;
            padding: 8px 16px;
            border-radius: 20px;
            font-size: 0.9em;
            margin-top: 10px;
        }
        
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        
        .stat-card {
            background: linear-gradient(135deg, var(--starko-light), var(--starko-lighter));
            border-radius: 15px;
            padding: 20px;
            border: 1px solid rgba(255,255,255,0.1);
            text-align: center;
        }
        
        .stat-value {
            font-size: 2em;
            font-weight: bold;
            margin-bottom: 5px;
        }
        
        .stat-label {
            color: var(--starko-text-secondary);
            font-size: 0.9em;
        }
        
        .profiles-section {
            background: rgba(26, 29, 34, 0.8);
            backdrop-filter: blur(20px);
            border-radius: 15px;
            padding: 25px;
            border: 1px solid var(--starko-lighter);
            margin-bottom: 25px;
        }
        
        .section-title {
            font-size: 1.4em;
            font-weight: 600;
            margin-bottom: 20px;
            text-align: center;
        }
        
        .profiles-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
            gap: 15px;
        }
        
        .profile-card {
            background: var(--starko-light);
            border: 1px solid var(--starko-lighter);
            border-radius: 12px;
            padding: 20px;
            transition: all 0.3s ease;
            cursor: pointer;
        }
        
        .profile-card:hover {
            border-color: var(--starko-primary);
            transform: translateY(-3px);
        }
        
        .profile-card.active {
            border-color: var(--starko-success);
            background: linear-gradient(135deg, var(--starko-light), #1a2a1a);
        }
        
        .profile-name {
            font-size: 1.1em;
            font-weight: 600;
            margin-bottom: 8px;
        }
        
        .profile-description {
            color: var(--starko-text-secondary);
            font-size: 0.9em;
            margin-bottom: 10px;
        }
        
        .profile-meta {
            display: flex;
            justify-content: space-between;
            font-size: 0.8em;
            color: var(--starko-text-secondary);
        }
        
        .active-badge {
            background: var(--starko-success);
            color: white;
            padding: 4px 8px;
            border-radius: 12px;
            font-size: 0.7em;
        }
        
        .actions-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
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
        
        .loading {
            text-align: center;
            padding: 40px;
            color: var(--starko-text-secondary);
        }
        
        .btn {
            background: linear-gradient(135deg, var(--starko-primary), var(--starko-secondary));
            color: white;
            border: none;
            padding: 10px 20px;
            border-radius: 8px;
            cursor: pointer;
            font-weight: 600;
            transition: all 0.3s ease;
            margin: 5px;
        }
        
        .btn:hover {
            transform: translateY(-2px);
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🤖 Starko AI Workspace 4.0</h1>
            <div class="subtitle">Aktualizováno na verzi s pokročilým systémem profilů</div>
            <div class="update-badge">ÚSPĚŠNĚ AKTUALIZOVÁNO</div>
            <div id="activeProfileBadge" style="margin-top: 15px; font-size: 0.9em;">
                Načítání profilu...
            </div>
        </div>

        <div class="stats-grid" id="systemStats">
            <div class="stat-card">
                <div class="stat-value" id="cpuUsage">0%</div>
                <div class="stat-label">Využití CPU</div>
            </div>
            <div class="stat-card">
                <div class="stat-value" id="memoryUsage">0%</div>
                <div class="stat-label">Využití RAM</div>
            </div>
            <div class="stat-card">
                <div class="stat-value" id="diskUsage">0%</div>
                <div class="stat-label">Využití Disku</div>
            </div>
            <div class="stat-card">
                <div class="stat-value" id="profilesCount">0</div>
                <div class="stat-label">Dostupných Profilů</div>
            </div>
        </div>

        <div class="profiles-section">
            <div class="section-title">🎯 Systém Profilů</div>
            <div class="profiles-grid" id="profilesList">
                <div class="loading">Načítání profilů...</div>
            </div>
        </div>

        <div class="profiles-section">
            <div class="section-title">⚡ Rychlé Akce</div>
            <div class="actions-grid">
                <div class="action-btn" onclick="switchProfile('ai-ml')">
                    <div class="action-icon">🧠</div>
                    <div>AI & ML Profil</div>
                </div>
                <div class="action-btn" onclick="switchProfile('web')">
                    <div class="action-icon">🌐</div>
                    <div>Web Profil</div>
                </div>
                <div class="action-btn" onclick="switchProfile('iot')">
                    <div class="action-icon">🍓</div>
                    <div>IoT Profil</div>
                </div>
                <div class="action-btn" onclick="switchProfile('full')">
                    <div class="action-icon">🚀</div>
                    <div>Kompletní Profil</div>
                </div>
            </div>
        </div>

        <div style="text-align: center; margin-top: 30px; color: var(--starko-text-secondary);">
            <p>Starko AI Workspace 4.0 | Aktualizováno: $(date +"%Y-%m-%d %H:%M")</p>
        </div>
    </div>

    <script>
        // Načtení systémového statusu
        async function loadSystemStatus() {
            try {
                const response = await fetch('/api/system/status');
                const systemData = await response.json();
                updateSystemStats(systemData);
                updateActiveProfile(systemData);
            } catch (error) {
                console.error('Chyba při načítání statusu:', error);
            }
        }

        // Načtení profilů
        async function loadProfiles() {
            try {
                const response = await fetch('/api/profiles');
                const profiles = await response.json();
                updateProfilesList(profiles);
            } catch (error) {
                console.error('Chyba při načítání profilů:', error);
                document.getElementById('profilesList').innerHTML = '<div class="loading">Chyba při načítání profilů</div>';
            }
        }

        // Aktualizace systémových statistik
        function updateSystemStats(systemData) {
            if (!systemData.performance) return;

            const perf = systemData.performance;
            const workspace = systemData.workspace;
            
            document.getElementById('cpuUsage').textContent = `${perf.cpu_usage}%`;
            document.getElementById('memoryUsage').textContent = `${perf.memory_percent}%`;
            document.getElementById('diskUsage').textContent = `${perf.disk_percent}%`;
            document.getElementById('profilesCount').textContent = workspace ? workspace.profiles_count : '0';
        }

        // Aktualizace seznamu profilů
        function updateProfilesList(profiles) {
            const container = document.getElementById('profilesList');
            
            if (!profiles || profiles.length === 0) {
                container.innerHTML = '<div class="loading">Profily nejsou dostupné</div>';
                return;
            }

            let html = '';
            profiles.forEach(profile => {
                const activeClass = profile.is_active ? 'active' : '';
                const activeBadge = profile.is_active ? '<span class="active-badge">AKTIVNÍ</span>' : '';
                
                html += `
                    <div class="profile-card ${activeClass}" onclick="switchProfile('${profile.id}')">
                        <div class="profile-name">${profile.name} ${activeBadge}</div>
                        <div class="profile-description">${profile.description}</div>
                        <div class="profile-meta">
                            <span>${profile.extensions_count} rozšíření</span>
                        </div>
                    </div>
                `;
            });
            
            container.innerHTML = html;
        }

        // Aktualizace aktivního profilu
        function updateActiveProfile(systemData) {
            if (!systemData.profile) return;
            
            const profile = systemData.profile;
            const badge = document.getElementById('activeProfileBadge');
            badge.innerHTML = `Aktivní profil: <strong>${profile.name}</strong> (${profile.active})`;
        }

        // Přepnutí profilu
        async function switchProfile(profileId) {
            if (!confirm(`Přepnout na profil "${profileId}"?`)) return;

            try {
                const response = await fetch('/api/profiles', {
                    method: 'POST',
                    headers: {'Content-Type': 'application/json'},
                    body: JSON.stringify({profile_id: profileId})
                });
                
                const result = await response.json();
                
                if (result.status === 'success') {
                    alert(result.message);
                    loadProfiles();
                    loadSystemStatus();
                } else {
                    alert('Chyba: ' + result.message);
                }
            } catch (error) {
                alert('Chyba při přepínání profilu: ' + error);
            }
        }

        // Inicializace
        document.addEventListener('DOMContentLoaded', function() {
            loadSystemStatus();
            loadProfiles();
            
            // Automatická aktualizace každých 10 sekund
            setInterval(loadSystemStatus, 10000);
        });
    </script>
</body>
</html>
EOF

    log_success "Dashboard template aktualizován"
}

# Funkce pro aktualizaci project manageru
update_project_manager() {
    log_step "Aktualizuji project manager..."
    
    if [ -f "projects/project_manager.py" ]; then
        cp "projects/project_manager.py" "projects/project_manager.py.backup"
    fi
    
    cat > "projects/project_manager.py" << 'EOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
AKTUALIZOVANÝ SPRÁVCE PROJEKTŮ STARKO AI WORKSPACE 4.0
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
        
    def create_project(self, project_name: str, project_type: str = "standard", profile: str = None):
        """Vytvoří nový projekt s podporou profilů"""
        project_path = self.projects_dir / project_name
        
        if project_path.exists():
            print(f"❌ Projekt '{project_name}' již existuje!")
            return False
        
        try:
            # Načtení aktuálního profilu
            if not profile:
                try:
                    profiles_file = self.workspace_root / "profiles" / "profiles.json"
                    with open(profiles_file, 'r') as f:
                        profiles_data = json.load(f)
                        profile = profiles_data.get('active_profile', 'full')
                except:
                    profile = 'full'
            
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
PROFIL: {profile}
STARKO AI WORKSPACE 4.0 - {datetime.now().year}
"""

import os
import sys
from pathlib import Path

def main():
    """Hlavní funkce projektu"""
    print("🚀 Vítejte v projektu {project_name}!")
    print(f"📍 Starko AI Workspace 4.0")
    print(f"🎯 Typ: {project_type}")
    print(f"🔧 Profil: {profile}")
    
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
                "profile": profile,
                "version": "1.0.0",
                "created": datetime.now().isoformat(),
                "starko_version": "4.0.0",
                "author": "Starko AI Workspace"
            }
            
            with open(project_path / "config" / "project.json", "w") as f:
                json.dump(config, f, indent=2)
            
            # README
            readme_content = f'''# {project_name}

Projekt vytvořený pomocí **Starko AI Workspace 4.0**.

## 🎯 Profil
Tento projekt byl vytvořen s profilem: **{profile}**

## 🚀 Spuštění

\`\`\`bash
python src/main.py
\`\`\`

## 📁 Struktura

- `src/` - Zdrojové kódy
- `tests/` - Testy
- `docs/` - Dokumentace  
- `config/` - Konfigurace
- `data/` - Data projektu

---
*Vytvořeno: {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}*
*Starko AI Workspace 4.0 - {profile} profile*
'''
            
            with open(project_path / "README.md", "w") as f:
                f.write(readme_content)
            
            print(f"✅ Projekt '{project_name}' vytvořen!")
            print(f"📍 Cesta: {project_path}")
            print(f"🎯 Profil: {profile}")
            print(f"🚀 Verze: Starko AI Workspace 4.0")
            return True
            
        except Exception as e:
            print(f"❌ Chyba při vytváření projektu: {e}")
            return False

def main():
    parser = argparse.ArgumentParser(description="Aktualizovaný správce projektů Starko AI Workspace 4.0")
    parser.add_argument("action", choices=["create", "list", "info"])
    parser.add_argument("--name", help="Název projektu")
    parser.add_argument("--type", default="standard", help="Typ projektu")
    parser.add_argument("--profile", help="Profil projektu")
    
    args = parser.parse_args()
    manager = StarkoProjectManager()
    
    if args.action == "create":
        if not args.name:
            print("❌ Zadejte název projektu: --name NAZEV")
            return
        manager.create_project(args.name, args.type, args.profile)
    elif args.action == "list":
        print("📂 Seznam projektů:")
        projects_dir = Path("projects")
        if projects_dir.exists():
            for project in projects_dir.iterdir():
                if project.is_dir():
                    print(f"  - {project.name}")
    elif args.action == "info":
        print("🤖 Starko AI Project Manager 4.0")
        print("Použití: python projects/project_manager.py create --name NAZEV --type TYP --profile PROFIL")

if __name__ == "__main__":
    main()
EOF

    chmod +x "projects/project_manager.py"
    log_success "Project manager aktualizován"
}

# Funkce pro vytvoření aktualizačního README
create_update_readme() {
    log_step "Vytvářím aktualizační dokumentaci..."
    
    cat > "UPDATE_4.0.md" << EOF
# 🚀 Starko AI Workspace - Aktualizace na verzi 4.0

## 📋 Přehled změn

### 🎯 Nový systém profilů
- **7 specializovaných profilů** pro různé typy projektů
- **Automatické přepínání** konfigurace a rozšíření
- **Webové rozhraní** pro správu profilů

### 🎨 Dostupné profily:
1. **minimal** - Základní nástroje
2. **python** - Python vývoj
3. **ai-ml** - AI a strojové učení  
4. **web** - Webový vývoj
5. **iot** - IoT a Raspberry Pi
6. **game** - Vývoj her
7. **full** - Všechny nástroje

### 🔧 Nové funkce
- **Správce profilů** - \`python scripts/profile_manager.py\`
- **Aktualizované Web GUI** s podporou profilů
- **Nové VS Code téma** - Starko Dark Pro
- **Vylepšený project manager** s podporou profilů

## 🚀 Rychlý start po aktualizaci

### 1. Spuštění Web GUI
\`\`\`bash
python web_gui/app.py
# Navštivte: http://localhost:8080
\`\`\`

### 2. Správa profilů
\`\`\`bash
# Seznam profilů
python scripts/profile_manager.py list

# Přepnutí na AI profil
python scripts/profile_manager.py switch --profile ai-ml

# Aktuální profil
python scripts/profile_manager.py active
\`\`\`

### 3. Vytvoření projektu s profilem
\`\`\`bash
python projects/project_manager.py create --name muj-projekt --profile ai-ml
\`\`\`

## 📊 Webové rozhraní

Nové Web GUI obsahuje:
- **Dashboard** s přehledem systémových zdrojů
- **Správu profilů** - přepínání kliknutím
- **Informace o workspace** - statistiky a metriky

## 🔄 Rollback (obnovení)

Pokud potřebujete obnovit původní verzi:
\`\`\`bash
# Záloha je uložena v: $BACKUP_DIR
cp -r $BACKUP_DIR/* ./
\`\`\`

## 📝 Poznámky k aktualizaci

- **Existující projekty** zůstávají nedotčené
- **VS Code nastavení** bylo aktualizováno
- **Web GUI** byl kompletně přepsán
- **Nové adresáře**: \`profiles/\`, \`themes/\`, \`icons/\`

---

**Starko AI Workspace 4.0**  
Aktualizováno: $(date +"%Y-%m-%d %H:%M:%S")

*Tato aktualizace přidává pokročilý systém profilů pro lepší přizpůsobení workspace vašim potřebám.*
EOF

    log_success "Aktualizační dokumentace vytvořena"
}

# Hlavní aktualizační funkce
main_update() {
    echo ""
    log_info "🎯 STARKO AI WORKSPACE - AKTUALIZACE NA VERZI 4.0"
    log_info "=================================================="
    echo ""
    
    # Kontroly
    check_workspace_exists
    
    # Potvrzení aktualizace
    echo -e "${YELLOW}⚠️  Chystáte se aktualizovat Starko Workspace na verzi 4.0${NC}"
    echo -e "${YELLOW}   Tato operace:${NC}"
    echo -e "${YELLOW}   - Vytvoří zálohu současného stavu${NC}"
    echo -e "${YELLOW}   - Aktualizuje VS Code konfiguraci${NC}"
    echo -e "${YELLOW}   - Přidá systém profilů${NC}"
    echo -e "${YELLOW}   - Aktualizuje Web GUI${NC}"
    echo ""
    read -p "Pokračovat v aktualizaci? (ano/ne): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Aa]$ ]]; then
        log_info "Aktualizace zrušena"
        exit 0
    fi
    
    # Provedení aktualizace
    create_backup
    create_new_directories
    update_vscode_config
    create_starko_theme
    create_profile_system
    create_profile_manager
    update_web_gui
    update_dashboard_template
    update_project_manager
    create_update_readme
    
    # Finální zpráva
    echo ""
    log_success "🎉 AKTUALIZACE NA VERZI 4.0 ÚSPĚŠNĚ DOKONČENA!"
    echo ""
    log_info "📋 PŘEHLED ZMĚN:"
    echo ""
    log_info "🎯 NOVÝ SYSTÉM PROFILŮ:"
    echo "   - 7 specializovaných profilů"
    echo "   - Rychlé přepínání konfigurace"
    echo "   - Automatická instalace rozšíření"
    echo ""
    log_info "🔧 SPRÁVA PROFILŮ:"
    echo "   python scripts/profile_manager.py list"
    echo "   python scripts/profile_manager.py switch --profile ai-ml"
    echo "   python scripts/profile_manager.py active"
    echo ""
    log_info "🌐 WEBOVÉ ROZHRANÍ:"
    echo "   python web_gui/app.py"
    echo "   http://localhost:8080"
    echo ""
    log_info "🚀 NOVÉ PROJEKTY:"
    echo "   python projects/project_manager.py create --name muj-projekt --profile ai-ml"
    echo ""
    log_info "📖 DOKUMENTACE:"
    echo "   Pro podrobnosti viz: UPDATE_4.0.md"
    echo ""
    log_info "💾 ZÁLOHA:"
    echo "   Soubory byly zálohovány do: $BACKUP_DIR"
    echo ""
    log_info "🎯 Jste připraveni používat pokročilý systém profilů Starko AI Workspace 4.0!"
}

# Spuštění hlavní aktualizační funkce
main_update
