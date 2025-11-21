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
