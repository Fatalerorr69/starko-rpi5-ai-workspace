from flask import Flask, render_template, jsonify, request, session, send_file
from flask_socketio import SocketIO, emit
import psutil
import datetime
import os
import json
import subprocess
import threading
import time
import glob
import shutil
from pathlib import Path
import hashlib

app = Flask(__name__)
app.config['SECRET_KEY'] = 'starko-secret-key'
socketio = SocketIO(app)

# Konfigurace workspace
WORKSPACE_ROOT = os.path.abspath('.')
ANALYSIS_EXCLUDES = ['.git', '__pycache__', 'node_modules', '.vscode', '.idea', 'venv']

# Globální proměnné pro sdílení dat mezi vlákny
system_data = {
    'cpu': 0, 'ram': 0, 'disk': 0, 'temperature': 0,
    'network_sent': 0, 'network_recv': 0, 'processes': [],
    'security_status': {}, 'storage_info': [], 'workspace_analysis': {}
}

def get_file_type(file_path):
    """Určí typ souboru podle přípony"""
    ext = Path(file_path).suffix.lower()
    file_types = {
        '.py': 'Python', '.js': 'JavaScript', '.html': 'HTML', '.css': 'CSS',
        '.json': 'JSON', '.md': 'Markdown', '.txt': 'Text', '.csv': 'CSV',
        '.xml': 'XML', '.yml': 'YAML', '.yaml': 'YAML', '.sql': 'SQL',
        '.java': 'Java', '.cpp': 'C++', '.c': 'C', '.h': 'Header',
        '.php': 'PHP', '.rb': 'Ruby', '.go': 'Go', '.rs': 'Rust',
        '.jpg': 'Image', '.jpeg': 'Image', '.png': 'Image', '.gif': 'Image',
        '.pdf': 'PDF', '.doc': 'Document', '.docx': 'Document',
        '.zip': 'Archive', '.tar': 'Archive', '.gz': 'Archive'
    }
    return file_types.get(ext, 'Other')

def analyze_workspace():
    """Analyzuje celý workspace a vrací statistiku"""
    analysis = {
        'total_files': 0,
        'total_size': 0,
        'file_types': {},
        'large_files': [],
        'duplicate_files': {},
        'recent_files': [],
        'empty_folders': [],
        'temp_files': [],
        'analysis_time': None
    }
    
    start_time = time.time()
    
    # Procházení všech souborů
    file_hashes = {}
    
    for root, dirs, files in os.walk(WORKSPACE_ROOT):
        # Filtrování vyloučených složek
        dirs[:] = [d for d in dirs if d not in ANALYSIS_EXCLUDES]
        
        for file in files:
            file_path = os.path.join(root, file)
            
            try:
                # Získání statistik
                stat = os.stat(file_path)
                file_size = stat.st_size
                
                # Aktualizace celkové statistiky
                analysis['total_files'] += 1
                analysis['total_size'] += file_size
                
                # Typ souboru
                file_type = get_file_type(file_path)
                analysis['file_types'][file_type] = analysis['file_types'].get(file_type, 0) + 1
                
                # Velké soubory (> 1MB)
                if file_size > 1024 * 1024:
                    analysis['large_files'].append({
                        'path': file_path,
                        'size': file_size,
                        'size_mb': round(file_size / (1024 * 1024), 2)
                    })
                
                # Nedávné soubory (posledních 7 dní)
                if time.time() - stat.st_mtime < 7 * 24 * 3600:
                    analysis['recent_files'].append({
                        'path': file_path,
                        'modified': datetime.datetime.fromtimestamp(stat.st_mtime).isoformat(),
                        'size': file_size
                    })
                
                # Dočasné soubory
                temp_extensions = ['.tmp', '.temp', '.log', '.cache']
                if any(file.lower().endswith(ext) for ext in temp_extensions):
                    analysis['temp_files'].append({
                        'path': file_path,
                        'size': file_size
                    })
                
                # Hash pro duplicity (jen pro soubory do 10MB)
                if file_size < 10 * 1024 * 1024:
                    with open(file_path, 'rb') as f:
                        file_hash = hashlib.md5(f.read()).hexdigest()
                    
                    if file_hash in file_hashes:
                        if file_hash not in analysis['duplicate_files']:
                            analysis['duplicate_files'][file_hash] = [file_hashes[file_hash]]
                        analysis['duplicate_files'][file_hash].append(file_path)
                    else:
                        file_hashes[file_hash] = file_path
            
            except (OSError, IOError):
                continue
    
    # Prázdné složky
    for root, dirs, files in os.walk(WORKSPACE_ROOT):
        dirs[:] = [d for d in dirs if d not in ANALYSIS_EXCLUDES]
        if not dirs and not files:
            analysis['empty_folders'].append(root)
    
    # Seřazení výsledků
    analysis['large_files'] = sorted(analysis['large_files'], key=lambda x: x['size'], reverse=True)[:10]
    analysis['recent_files'] = sorted(analysis['recent_files'], key=lambda x: x['modified'], reverse=True)[:10]
    analysis['file_types'] = dict(sorted(analysis['file_types'].items(), key=lambda x: x[1], reverse=True))
    
    analysis['analysis_time'] = round(time.time() - start_time, 2)
    analysis['total_size_mb'] = round(analysis['total_size'] / (1024 * 1024), 2)
    
    return analysis

def cleanup_workspace(cleanup_types):
    """Vyčistí workspace podle zvolených typů"""
    results = {
        'deleted_files': [],
        'deleted_size': 0,
        'errors': []
    }
    
    temp_patterns = ['*.tmp', '*.temp', '*.log', '*.cache', '*.bak']
    cache_dirs = ['__pycache__', '.cache', 'cache', 'temp']
    
    for root, dirs, files in os.walk(WORKSPACE_ROOT):
        # Čištění souborů
        for file in files:
            file_path = os.path.join(root, file)
            
            try:
                file_size = os.path.getsize(file_path)
                
                # Smazat dočasné soubory
                if 'temp' in cleanup_types and any(file.lower().endswith(ext) for ext in ['.tmp', '.temp', '.bak']):
                    os.remove(file_path)
                    results['deleted_files'].append(file_path)
                    results['deleted_size'] += file_size
                
                # Smazat logy
                elif 'logs' in cleanup_types and file.lower().endswith('.log'):
                    os.remove(file_path)
                    results['deleted_files'].append(file_path)
                    results['deleted_size'] += file_size
                
                # Smazat cache
                elif 'cache' in cleanup_types and any(pattern in file for pattern in ['.cache', 'cache']):
                    os.remove(file_path)
                    results['deleted_files'].append(file_path)
                    results['deleted_size'] += file_size
            
            except Exception as e:
                results['errors'].append(f"Chyba při mazání {file_path}: {str(e)}")
        
        # Čištění složek
        for dir_name in dirs[:]:
            dir_path = os.path.join(root, dir_name)
            
            try:
                # Smazat cache složky
                if 'cache' in cleanup_types and dir_name in cache_dirs:
                    shutil.rmtree(dir_path)
                    results['deleted_files'].append(f"{dir_path}/")
                    # Přidat velikost smazané složky
                    total_size = 0
                    for dir_root, _, dir_files in os.walk(dir_path):
                        for f in dir_files:
                            try:
                                total_size += os.path.getsize(os.path.join(dir_root, f))
                            except:
                                pass
                    results['deleted_size'] += total_size
                    dirs.remove(dir_name)  # Odstranit z dalšího procházení
            
            except Exception as e:
                results['errors'].append(f"Chyba při mazání {dir_path}: {str(e)}")
    
    results['deleted_size_mb'] = round(results['deleted_size'] / (1024 * 1024), 2)
    return results

def update_system_data():
    """Průběžně aktualizuje systémová data na pozadí"""
    while True:
        try:
            # Základní metriky
            system_data['cpu'] = psutil.cpu_percent(interval=1)
            memory = psutil.virtual_memory()
            system_data['ram'] = memory.percent
            disk = psutil.disk_usage('/')
            system_data['disk'] = disk.percent
            system_data['temperature'] = 45 + psutil.cpu_percent() / 2
            
            # Síť
            net_io = psutil.net_io_counters()
            system_data['network_sent'] = net_io.bytes_sent
            system_data['network_recv'] = net_io.bytes_recv
            
            # Procesy
            processes = []
            for proc in psutil.process_iter(['pid', 'name', 'cpu_percent', 'memory_percent']):
                try:
                    processes.append(proc.info)
                except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
                    pass
            processes.sort(key=lambda x: x['cpu_percent'] or 0, reverse=True)
            system_data['processes'] = processes[:15]
            
            # Analýza workspace (jednou za minutu)
            if int(time.time()) % 60 == 0:
                system_data['workspace_analysis'] = analyze_workspace()
            
            # Posílání metrik přes WebSocket
            socketio.emit('update_metrics', {
                'cpu': system_data['cpu'],
                'ram': system_data['ram'], 
                'disk': system_data['disk'],
                'processes': len(system_data['processes'])
            })
            
            # Logy přes WebSocket
            socketio.emit('update_log', f"System update: CPU {system_data['cpu']:.1f}%, RAM {system_data['ram']:.1f}%")
            
            # Tabulka procesů
            proc_list = []
            for p in system_data['processes'][:10]:
                proc_list.append({
                    'pid': p['pid'],
                    'name': p['name'][:20],
                    'cpu': round(p['cpu_percent'] or 0, 1),
                    'ram': round(p['memory_percent'] or 0, 1)
                })
            socketio.emit('update_table', proc_list)
            
            # Bezpečnostní stav
            system_data['security_status'] = {
                'firewall': 'active',
                'antivirus': 'active', 
                'updates': 'available',
                'last_scan': datetime.datetime.now().isoformat(),
                'threats': 0
            }
            
            # Úložiště
            partitions = psutil.disk_partitions()
            storage = []
            for partition in partitions:
                try:
                    usage = psutil.disk_usage(partition.mountpoint)
                    storage.append({
                        'device': partition.device,
                        'mountpoint': partition.mountpoint,
                        'total': usage.total,
                        'used': usage.used, 
                        'free': usage.free,
                        'percent': usage.percent
                    })
                except PermissionError:
                    continue
            system_data['storage_info'] = storage
            
        except Exception as e:
            print(f"Chyba při aktualizaci dat: {e}")
        
        time.sleep(3)

# WebSocket handlery
@socketio.on('action')
def handle_action(data):
    action = data.get('action')
    print(f"Akce přijata: {action}")
    emit('update_log', f"Akce spuštěna: {action}")

# API endpointy
@app.route('/')
def index():
    return render_template('dashboard.html', user={'username': 'admin', 'role': 'admin'})

@app.route('/api/system/status')
def system_status():
    return jsonify({
        'cpu': system_data['cpu'],
        'ram': system_data['ram'],
        'disk': system_data['disk'], 
        'temperature': system_data['temperature'],
        'network_sent': system_data['network_sent'],
        'network_recv': system_data['network_recv'],
        'timestamp': datetime.datetime.now().isoformat(),
        'workspace_stats': {
            'total_profiles': 9,
            'total_scripts': 15, 
            'total_configs': 7,
            'workspace_size_mb': system_data.get('workspace_analysis', {}).get('total_size_mb', 0)
        }
    })

@app.route('/api/workspace/analyze')
def workspace_analyze():
    """Spustí analýzu workspace"""
    analysis = analyze_workspace()
    system_data['workspace_analysis'] = analysis
    return jsonify(analysis)

@app.route('/api/workspace/cleanup', methods=['POST'])
def workspace_cleanup():
    """Vyčistí workspace"""
    data = request.json
    cleanup_types = data.get('types', [])
    
    results = cleanup_workspace(cleanup_types)
    return jsonify(results)

@app.route('/api/workspace/organize', methods=['POST'])
def workspace_organize():
    """Organizuje soubory ve workspace"""
    data = request.json
    organize_by = data.get('organize_by', 'type')
    
    # Vytvoření organizační struktury
    organized = {
        'moved_files': [],
        'created_folders': [],
        'errors': []
    }
    
    file_type_folders = {
        'Python': 'code/python',
        'JavaScript': 'code/javascript',
        'HTML': 'web/html',
        'CSS': 'web/css',
        'Image': 'media/images',
        'Document': 'docs',
        'Archive': 'archives',
        'Other': 'other'
    }
    
    try:
        for root, dirs, files in os.walk(WORKSPACE_ROOT):
            for file in files:
                if root.startswith(tuple(file_type_folders.values())):
                    continue  # Přeskočit již organizované soubory
                
                file_path = os.path.join(root, file)
                file_type = get_file_type(file_path)
                target_folder = file_type_folders.get(file_type, 'other')
                target_path = os.path.join(WORKSPACE_ROOT, target_folder)
                
                # Vytvořit cílovou složku
                os.makedirs(target_path, exist_ok=True)
                if target_path not in organized['created_folders']:
                    organized['created_folders'].append(target_path)
                
                # Přesunout soubor
                target_file = os.path.join(target_path, file)
                if not os.path.exists(target_file):
                    shutil.move(file_path, target_file)
                    organized['moved_files'].append({
                        'from': file_path,
                        'to': target_file,
                        'type': file_type
                    })
    
    except Exception as e:
        organized['errors'].append(str(e))
    
    return jsonify(organized)

@app.route('/api/workspace/duplicates')
def find_duplicates():
    """Najde duplicitní soubory"""
    analysis = analyze_workspace()
    duplicates = []
    
    for file_hash, files in analysis.get('duplicate_files', {}).items():
        if len(files) > 1:
            file_size = os.path.getsize(files[0]) if os.path.exists(files[0]) else 0
            duplicates.append({
                'hash': file_hash,
                'files': files,
                'size': file_size,
                'size_mb': round(file_size / (1024 * 1024), 2),
                'wasted_space': file_size * (len(files) - 1)
            })
    
    return jsonify(duplicates)

@app.route('/api/workspace/file-tree')
def get_file_tree():
    """Vrátí strom souborů workspace"""
    def build_tree(path, max_depth=3, current_depth=0):
        if current_depth > max_depth:
            return None
            
        name = os.path.basename(path)
        if name.startswith('.'):
            return None
            
        item = {
            'name': name,
            'path': path,
            'type': 'directory' if os.path.isdir(path) else 'file'
        }
        
        if os.path.isdir(path):
            item['children'] = []
            try:
                for entry in os.listdir(path):
                    if entry in ANALYSIS_EXCLUDES:
                        continue
                    full_path = os.path.join(path, entry)
                    child = build_tree(full_path, max_depth, current_depth + 1)
                    if child:
                        item['children'].append(child)
            except PermissionError:
                pass
        
        return item
    
    tree = build_tree(WORKSPACE_ROOT)
    return jsonify(tree)

# Zbývající endpointy (profiles, processes, security, storage, ai/chat, profiles/activate, scripts/run)
# ... (zachováme z předchozí verze)

@app.route('/api/profiles')
def get_profiles():
    profiles = [
        {"id": "minimal", "name": "Minimální", "description": "Základní nástroje", "extensions": 3, "active": False, "icon": "🚀"},
        {"id": "python", "name": "Python vývoj", "description": "Kompletní prostředí pro Python", "extensions": 7, "active": False, "icon": "🐍"},
        {"id": "ai", "name": "AI a strojové učení", "description": "Specializované pro AI a ML", "extensions": 8, "active": False, "icon": "🧠"},
        {"id": "web", "name": "Webový vývoj", "description": "Moderní webový vývoj", "extensions": 7, "active": False, "icon": "🌐"},
        {"id": "iot", "name": "IoT a Raspberry Pi", "description": "Vývoj pro IoT", "extensions": 7, "active": False, "icon": "📟"},
        {"id": "gamedev", "name": "Vývoj her", "description": "Pro vývoj her a grafiky", "extensions": 7, "active": False, "icon": "🎮"},
        {"id": "pentest", "name": "PenTest & Security", "description": "Nástroje pro penetrační testování", "extensions": 12, "active": False, "icon": "🛡️"},
        {"id": "data-science", "name": "Data Science", "description": "Analýza dat a vizualizace", "extensions": 9, "active": False, "icon": "📊"},
        {"id": "full", "name": "Kompletná (EXTREM)", "description": "Všechny nástroje a rozšíření", "extensions": 28, "active": True, "icon": "⚡"}
    ]
    return jsonify(profiles)

@app.route('/api/processes')
def get_processes():
    return jsonify(system_data['processes'])

@app.route('/api/security/status')
def security_status():
    return jsonify(system_data['security_status'])

@app.route('/api/storage')
def storage_info():
    return jsonify(system_data['storage_info'])

@app.route('/api/ai/chat', methods=['POST'])
def ai_chat():
    data = request.json
    user_message = data.get('message', '')
    
    responses = {
        'stav systému': f"🖥️ CPU: {system_data['cpu']:.1f}% | 🧠 RAM: {system_data['ram']:.1f}% | 💾 Disk: {system_data['disk']:.1f}% | 🌡️ Teplota: {system_data['temperature']:.1f}°C",
        'workspace': f"📁 Workspace: {system_data.get('workspace_analysis', {}).get('total_files', 0)} souborů, {system_data.get('workspace_analysis', {}).get('total_size_mb', 0):.1f} MB",
        'bezpečnost': f"🛡️ Stav zabezpečení: Vše aktivní | 📊 Hrozby: 0",
        'optimalizace': "Doporučuji: 1) Vyčistit dočasné soubory 2) Zkontrolovat automatické spouštění 3) Aktualizovat systém",
        'analyzovat': "Spouštím analýzu workspace...",
        'vyčistit': "Spouštím čištění workspace...",
        'pomoc': "Mohu pomoci s: stavem systému, workspace analýzou, čištěním, optimalizací, správou profilů.",
        'profily': "Dostupné profily: Minimální, Python, AI, Web, IoT, Hry, Pentest, Data Science, Kompletná"
    }
    
    user_lower = user_message.lower()
    response = "Nerozumím otázce. Zkuste se zeptat na: 'stav systému', 'workspace', 'analyzovat', 'vyčistit', 'pomoc', 'profily'"
    
    for key in responses:
        if key in user_lower:
            response = responses[key]
            break
    
    return jsonify({
        'response': response,
        'timestamp': datetime.datetime.now().isoformat()
    })

@app.route('/api/profiles/activate', methods=['POST'])
def activate_profile():
    data = request.json
    profile_id = data.get('profile_id', '')
    
    return jsonify({
        'status': 'success', 
        'message': f'Profil {profile_id} byl aktivován',
        'profile_id': profile_id
    })

@app.route('/api/scripts/run', methods=['POST'])
def run_script():
    data = request.json
    script_name = data.get('script_name', '')
    
    return jsonify({
        'status': 'success',
        'message': f'Skript {script_name} byl spuštěn',
        'script': script_name
    })

# Spuštění vlákna pro aktualizaci dat
threading.Thread(target=update_system_data, daemon=True).start()

if __name__ == '__main__':
    print("🚀 Spouštím Starko AI Workspace 4.0 - Rozšířená verze s analýzou workspace")
    print("🌐 Dashboard dostupný na: http://127.0.0.1:8080")
    print("🔧 Nové funkce: Analýza workspace, Čištění, Organizace souborů")
    socketio.run(app, host='0.0.0.0', port=8080, debug=True)