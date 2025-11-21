#!/usr/bin/env python3
import subprocess
import sys
import os
import time

def start_webgui():
    """Spustí webGUI automaticky"""
    print("🚀 Starko AI Workspace - Auto start WebGUI")
    print("⏳ Spouštím dashboard...")
    
    webgui_path = os.path.join(os.path.dirname(__file__), 'app.py')
    
    if os.path.exists(webgui_path):
        try:
            # Spustit webGUI na pozadí
            process = subprocess.Popen([sys.executable, webgui_path])
            print("✅ WebGUI úspěšně spuštěno")
            print("🌐 Dashboard: http://127.0.0.1:8080")
            print("📱 Multi-device: http://10.0.0.71:8080")
            print("🛑 Pro zastavení: Ctrl+C")
            
            # Počkat na ukončení
            process.wait()
            
        except Exception as e:
            print(f"❌ Chyba při spouštění: {e}")
    else:
        print("❌ web_gui/app.py nenalezen")

if __name__ == '__main__':
    start_webgui()
