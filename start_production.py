#!/usr/bin/env python3
import subprocess
import sys
import os

def main():
    print("🚀 STARTOVÁNÍ STARTO AI WORKSPACE 4.0")
    print("=" * 50)
    
    # Kontrola závislostí
    try:
        import waitress
        import flask
        import psutil
        print("✅ Všechny závislosti jsou nainstalovány")
    except ImportError as e:
        print(f"❌ Chybějící závislost: {e}")
        print("Instalace závislostí...")
        subprocess.check_call([sys.executable, "-m", "pip", "install", "waitress", "flask", "psutil"])
        print("✅ Závislosti nainstalovány")
    
    # Spuštění serveru
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    from web_gui.production_server import app, init_db
    
    init_db()
    print("🌐 SERVER SPUŠTĚN:")
    print("   • Local:  http://127.0.0.1:8080")
    print("   • Network: http://YOUR-IP:8080")
    print("   • Demo: admin / admin123")
    print("\n⚡ PRODUKČNÍ REŽIM • MULTI-USER • RYCHLÝ")
    
    # Spuštění Waitress serveru
    from waitress import serve
    serve(app, host='0.0.0.0', port=8080, threads=8)

if __name__ == '__main__':
    main()
