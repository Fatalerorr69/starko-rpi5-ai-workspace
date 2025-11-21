#!/usr/bin/env python3
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
        print("\\n🛑 Server ukončen")
    except Exception as e:
        print(f"❌ Chyba: {e}")
