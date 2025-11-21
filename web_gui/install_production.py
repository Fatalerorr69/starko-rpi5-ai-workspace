#!/usr/bin/env python3
import subprocess
import sys
import os

def install_production_deps():
    """Nainstaluje produkční závislosti"""
    packages = ['waitress', 'gunicorn', 'whitenoise']
    
    for package in packages:
        try:
            subprocess.check_call([sys.executable, '-m', 'pip', 'install', package])
            print(f"✅ {package} nainstalován")
        except subprocess.CalledProcessError:
            print(f"❌ Chyba při instalaci {package}")

def create_production_config():
    """Vytvoří produkční konfiguraci"""
    config = """
# Starko AI Workspace - Production Configuration
DEBUG=False
PORT=8080
HOST=0.0.0.0
WORKERS=4
THREADS=2
"""

    with open('production.env', 'w') as f:
        f.write(config)
    
    print("✅ Produkční konfigurace vytvořena")

if __name__ == '__main__':
    print("🔄 Příprava produkčního prostředí...")
    install_production_deps()
    create_production_config()
    print("🎉 Produkční prostředí připraveno!")
    print("👉 Spusťte: python web_gui/wsgi.py")