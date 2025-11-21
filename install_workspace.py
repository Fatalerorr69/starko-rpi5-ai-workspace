#!/usr/bin/env python3
"""
Hlavní instalační skript pro Starko AI Workspace
Integruje všechny komponenty z vašeho repozitáře
"""
import os
import sys
import subprocess
import shutil

def install_dependencies():
    """Nainstaluje všechny potřebné závislosti"""
    print("📦 Instalace závislostí...")
    
    requirements = [
        'flask==2.3.3',
        'waitress==2.1.2', 
        'psutil==5.9.5',
        'werkzeug==2.3.7',
        'py-cpuinfo==9.0.0',
        'gputil==1.4.0'
    ]
    
    for package in requirements:
        try:
            subprocess.check_call([sys.executable, '-m', 'pip', 'install', package])
            print(f"✅ {package}")
        except subprocess.CalledProcessError:
            print(f"❌ Chyba při instalaci {package}")

def setup_directories():
    """Vytvoří potřebnou adresářovou strukturu"""
    print("📁 Příprava adresářové struktury...")
    
    directories = [
        'web_gui/templates',
        'web_gui/static',
        'scripts/system',
        'scripts/security', 
        'scripts/automation',
        'database',
        'logs',
        'backups',
        'temp'
    ]
    
    for directory in directories:
        os.makedirs(directory, exist_ok=True)
        print(f"✅ {directory}")

def setup_profiles():
    """Nastaví profily z vašeho repozitáře"""
    print("🎯 Příprava profilů...")
    
    # Zkontrolovat existující profily
    profiles = ['StarkoPenTest', 'StarkoDarkPro', 'StarkoAI']
    
    for profile in profiles:
        if os.path.exists(f'profiles/{profile}'):
            print(f"✅ Nalezen profil: {profile}")
        else:
            print(f"⚠️  Profil {profile} nebyl nalezen")

def create_startup_scripts():
    """Vytvoří spouštěcí skripty"""
    print("🚀 Vytváření spouštěcích skriptů...")
    
    # Hlavní startovací skript
    with open('start_workspace.py', 'w', encoding='utf-8') as f:
        f.write('''#!/usr/bin/env python3
import os
import sys
import webbrowser
import time

# Přidat aktuální adresář do Python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

def main():
    print("🚀 Spouštím Starko AI Workspace...")
    print("⏳ Načítám konfiguraci...")
    
    # Počkat na načtení
    time.sleep(2)
    
    # Otevřít prohlížeč
    webbrowser.open('http://127.0.0.1:8080')
    
    # Spustit server
    from web_gui.production_server import app, init_db
    
    init_db()
    print("✅ Server připraven")
    print("🌐 https://127.0.0.1:8080")
    
    from waitress import serve
    serve(app, host='0.0.0.0', port=8080, threads=6)

if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print("\\\\n🛑 Server ukončen")
    except Exception as e:
        print(f"❌ Chyba: {e}")
''')
    
    print("✅ Spouštěcí skript vytvořen")

if __name__ == '__main__':
    print("🛠️  INSTALACE STARTO AI WORKSPACE")
    print("=" * 50)
    
    install_dependencies()
    setup_directories()
    setup_profiles()
    create_startup_scripts()
    
    print("=" * 50)
    print("🎉 INSTALACE DOKONČENA!")
    print("👉 Spusťte: python start_workspace.py")
    print("🌐 Otevře se: http://127.0.0.1:8080")