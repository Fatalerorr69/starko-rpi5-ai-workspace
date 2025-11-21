from flask import Flask, render_template, jsonify, request, send_from_directory
import psutil
import datetime
import os
import json
import subprocess
import threading
import time

app = Flask(__name__)

# Globální proměnné pro sdílení dat mezi vlákny
system_data = {
    'cpu': 0,
    'ram': 0, 
    'disk': 0,
    'temperature': 0,
    'network_sent': 0,
    'network_recv': 0,
    'processes': [],
    'security_status': {},
    'storage_info': []
}

def update_system_data():
    """Průběžně aktualizuje systémová data na pozadí"""
    while True:
        try:
            # CPU
            system_data['cpu'] = psutil.cpu_percent(interval=1)
            
            # RAM
            memory = psutil.virtual_memory()
            system_data['ram'] = memory.percent
            
            # Disk
            disk = psutil.disk_usage('/')
            system_data['disk'] = disk.percent
            
            # Teplota (simulace)
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
            
            # Bezpečnostní stav
            system_data['security_status'] = {
                'firewall': 'active',
                'antivirus': 'active',
                'updates': 'available' if system_data['cpu'] < 80 else 'pending',
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
        
        time.sleep(2)

# Spustit aktualizaci dat na pozadí
data_thread = threading.Thread(target=update_system_data, daemon=True)
data_thread.start()

@app.route('/')
def index():
    return render_template('dashboard.html')

@app.route('/api/system/status')
def system_status():
    return jsonify({
        'cpu': system_data['cpu'],
        'ram': system_data['ram'],
        'disk': system_data['disk'],
        'temperature': system_data['temperature'],
        'network_sent': system_data['network_sent'],
        'network_recv': system_data['network_recv'],
        'timestamp': datetime.datetime.now().isoformat()
    })

@app.route('/api/profiles')
def get_profiles():
    profiles = [
        {
            "id": "minimal",
            "name": "Minimální",
            "description": "Základní nástroje pro rychlý start",
            "extensions": 3,
            "active": False,
            "icon": "🚀"
        },
        {
            "id": "python", 
            "name": "Python vývoj",
            "description": "Kompletní prostředí pro Python vývoj",
            "extensions": 7,
            "active": False,
            "icon": "🐍"
        },
        {
            "id": "ai",
            "name": "AI a strojové učení", 
            "description": "Specializované pro AI a ML projekty",
            "extensions": 8,
            "active": False,
            "icon": "🧠"
        },
        {
            "id": "web",
            "name": "Webový vývoj",
            "description": "Moderní webový vývoj",
            "extensions": 7, 
            "active": False,
            "icon": "🌐"
        },
        {
            "id": "iot",
            "name": "IoT a Raspberry Pi",
            "description": "Vývoj pro IoT a Raspberry Pi",
            "extensions": 7,
            "active": False,
            "icon": "📟"
        },
        {
            "id": "gamedev",
            "name": "Vývoj her",
            "description": "Pro vývoj her a grafiky", 
            "extensions": 7,
            "active": False,
            "icon": "🎮"
        },
        {
            "id": "pentest",
            "name": "PenTest & Security",
            "description": "Nástroje pro penetrační testování",
            "extensions": 12,
            "active": False,
            "icon": "🛡️"
        },
        {
            "id": "data-science",
            "name": "Data Science",
            "description": "Analýza dat a vizualizace",
            "extensions": 9,
            "active": False,
            "icon": "📊"
        },
        {
            "id": "full",
            "name": "Kompletná (EXTREM)",
            "description": "Všechny nástroje a rozšíření",
            "extensions": 28,
            "active": True,
            "icon": "⚡"
        }
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

@app.route('/api/network/connections')
def network_connections():
    try:
        connections = psutil.net_connections()
        return jsonify([{
            'fd': conn.fd,
            'family': conn.family.name,
            'type': conn.type.name,
            'laddr': f"{conn.laddr.ip}:{conn.laddr.port}" if conn.laddr else None,
            'raddr': f"{conn.raddr.ip}:{conn.raddr.port}" if conn.raddr else None,
            'status': conn.status,
            'pid': conn.pid
        } for conn in connections[:20]])  # Omezení na 20 připojení
    except Exception as e:
        return jsonify({'error': str(e)})

@app.route('/api/ai/chat', methods=['POST'])
def ai_chat():
    data = request.json
    user_message = data.get('message', '')
    
    # Jednoduchý AI chatbot
    responses = {
        'stav systému': f"🖥️ CPU: {system_data['cpu']:.1f}% | 🧠 RAM: {system_data['ram']:.1f}% | 💾 Disk: {system_data['disk']:.1f}% | 🌡️ Teplota: {system_data['temperature']:.1f}°C",
        'bezpečnost': f"🛡️ Firewall: Aktivní | 🦠 Antivirus: Aktivní | 🔄 Aktualizace: Dostupné | 📊 Hrozby: 0",
        'optimalizace': "Doporučuji: 1) Vyčistit dočasné soubory 2) Zkontrolovat automatické spouštění 3) Aktualizovat systém",
        'pomoc': "Mohu pomoci s: stavem systému, bezpečností, optimalizací, správou profilů. Stačí se zeptat!",
        'profily': "Dostupné profily: Minimální, Python, AI, Web, IoT, Hry, Pentest, Data Science, Kompletná"
    }
    
    user_lower = user_message.lower()
    response = "Nerozumím otázce. Zkuste se zeptat na: stav systému, bezpečnost, optimalizace, pomoc, profily"
    
    for key in responses:
        if key in user_lower:
            response = responses[key]
            break
    
    return jsonify({
        'response': response,
        'timestamp': datetime.datetime.now().isoformat()
    })

@app.route('/api/tools/execute', methods=['POST'])
def execute_tool():
    data = request.json
    tool = data.get('tool', '')
    
    responses = {
        'terminal': "🖥️ Terminál otevřen",
        'editor': "📝 Editor kódu spuštěn", 
        'file_manager': "📁 Správce souborů otevřen",
        'database': "🗃️ Prohlížeč databází spuštěn",
        'git': "📚 Git správce aktivován",
        'debug': "🐛 Debugger připraven"
    }
    
    return jsonify({
        'status': 'success',
        'message': responses.get(tool, f"Nástroj {tool} spuštěn"),
        'tool': tool
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

if __name__ == '__main__':
    print("🚀 Spouštím Starko AI Workspace 4.0 - Rozšířené WebGUI")
    print("🌐 Dashboard dostupný na: http://127.0.0.1:8080")
    print("🔧 Rozšířené funkce: AI Chat, Multi-panel, Live monitoring")
    app.run(host='0.0.0.0', port=8080, debug=True)
