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
