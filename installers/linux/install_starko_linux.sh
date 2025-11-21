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
