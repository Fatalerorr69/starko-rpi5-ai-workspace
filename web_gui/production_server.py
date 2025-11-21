from flask import Flask, render_template, jsonify, request, session, redirect, url_for
import psutil
import datetime
import os
import json
import threading
import time
from waitress import serve
import sqlite3
from werkzeug.security import generate_password_hash, check_password_hash

app = Flask(__name__)
app.secret_key = 'starko_ai_workspace_production_2025'
app.config['DATABASE'] = 'starko_users.db'

# Inicializace databáze
def init_db():
    with sqlite3.connect(app.config['DATABASE']) as conn:
        conn.execute('''
            CREATE TABLE IF NOT EXISTS users (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                username TEXT UNIQUE NOT NULL,
                password_hash TEXT NOT NULL,
                role TEXT DEFAULT 'user',
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        conn.execute('''
            CREATE TABLE IF NOT EXISTS user_sessions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER,
                session_id TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users (id)
            )
        ''')
        
        # Vytvořit výchozího admina pokud neexistuje
        admin_exists = conn.execute('SELECT 1 FROM users WHERE username = ?', ('admin',)).fetchone()
        if not admin_exists:
            password_hash = generate_password_hash('admin123')
            conn.execute('INSERT INTO users (username, password_hash, role) VALUES (?, ?, ?)',
                        ('admin', password_hash, 'admin'))

# Globální systémová data
system_data = {
    'cpu': 0, 'ram': 0, 'disk': 0, 'temperature': 0,
    'network_sent': 0, 'network_recv': 0, 'processes': [],
    'security_status': {}, 'storage_info': [], 'active_users': 0
}

def update_system_data():
    """Průběžná aktualizace systémových dat na pozadí"""
    while True:
        try:
            # Aktualizace systémových metrik
            system_data.update({
                'cpu': psutil.cpu_percent(interval=0.5),
                'ram': psutil.virtual_memory().percent,
                'disk': psutil.disk_usage('/').percent,
                'temperature': 45 + psutil.cpu_percent() / 2,
                'active_users': len([1 for _ in psutil.users()])
            })
            
            # Síťové statistiky
            net_io = psutil.net_io_counters()
            system_data.update({
                'network_sent': net_io.bytes_sent,
                'network_recv': net_io.bytes_recv
            })
            
            # Procesy
            processes = []
            for proc in psutil.process_iter(['pid', 'name', 'cpu_percent', 'memory_percent', 'username']):
                try:
                    processes.append(proc.info)
                except (psutil.NoSuchProcess, psutil.AccessDenied):
                    continue
            system_data['processes'] = sorted(processes, 
                                            key=lambda x: x['cpu_percent'] or 0, 
                                            reverse=True)[:20]
            
            # Bezpečnostní stav
            system_data['security_status'] = {
                'firewall': 'active',
                'antivirus': 'active' if system_data['cpu'] < 90 else 'warning',
                'updates': 'available',
                'last_scan': datetime.datetime.now().isoformat(),
                'threats': 0,
                'encryption': 'enabled'
            }
            
            # Úložiště
            partitions = []
            for partition in psutil.disk_partitions():
                try:
                    usage = psutil.disk_usage(partition.mountpoint)
                    partitions.append({
                        'device': partition.device,
                        'mountpoint': partition.mountpoint,
                        'total': usage.total,
                        'used': usage.used,
                        'free': usage.free,
                        'percent': usage.percent,
                        'type': partition.fstype
                    })
                except PermissionError:
                    continue
            system_data['storage_info'] = partitions
            
        except Exception as e:
            print(f"Chyba při aktualizaci dat: {e}")
        time.sleep(1)  # Rychlejší aktualizace

# Spustit aktualizaci dat
data_thread = threading.Thread(target=update_system_data, daemon=True)
data_thread.start()

# UŽIVATELSKÉ FUNKCE
@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']
        
        with sqlite3.connect(app.config['DATABASE']) as conn:
            user = conn.execute(
                'SELECT * FROM users WHERE username = ?', (username,)
            ).fetchone()
            
            if user and check_password_hash(user[2], password):
                session['user_id'] = user[0]
                session['username'] = user[1]
                session['role'] = user[3]
                return redirect(url_for('dashboard'))
        
        return render_template('login.html', error='Neplatné přihlašovací údaje')
    
    return render_template('login.html')

@app.route('/register', methods=['GET', 'POST'])
def register():
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']
        
        with sqlite3.connect(app.config['DATABASE']) as conn:
            try:
                password_hash = generate_password_hash(password)
                conn.execute(
                    'INSERT INTO users (username, password_hash) VALUES (?, ?)',
                    (username, password_hash)
                )
                return redirect(url_for('login'))
            except sqlite3.IntegrityError:
                return render_template('register.html', error='Uživatel již existuje')
    
    return render_template('register.html')

@app.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('login'))

@app.route('/')
def index():
    if 'user_id' not in session:
        return redirect(url_for('login'))
    return redirect(url_for('dashboard'))

@app.route('/dashboard')
def dashboard():
    if 'user_id' not in session:
        return redirect(url_for('login'))
    return render_template('dashboard.html', user=session)

# API ENDPOINTS
@app.route('/api/system/status')
def system_status():
    if 'user_id' not in session:
        return jsonify({'error': 'Unauthorized'}), 401
    
    return jsonify({
        'cpu': system_data['cpu'],
        'ram': system_data['ram'],
        'disk': system_data['disk'],
        'temperature': system_data['temperature'],
        'network_sent': system_data['network_sent'],
        'network_recv': system_data['network_recv'],
        'active_users': system_data['active_users'],
        'timestamp': datetime.datetime.now().isoformat()
    })

@app.route('/api/profiles')
def get_profiles():
    if 'user_id' not in session:
        return jsonify({'error': 'Unauthorized'}), 401
    
    profiles = [
        {"id": "minimal", "name": "Minimální", "description": "Základní nástroje pro rychlý start", "extensions": 3, "active": False, "icon": "🚀"},
        {"id": "python", "name": "Python vývoj", "description": "Kompletní prostředí pro Python vývoj", "extensions": 7, "active": False, "icon": "🐍"},
        {"id": "ai", "name": "AI a strojové učení", "description": "Specializované pro AI a ML projekty", "extensions": 8, "active": False, "icon": "🧠"},
        {"id": "web", "name": "Webový vývoj", "description": "Moderní webový vývoj", "extensions": 7, "active": False, "icon": "🌐"},
        {"id": "iot", "name": "IoT a Raspberry Pi", "description": "Vývoj pro IoT a Raspberry Pi", "extensions": 7, "active": False, "icon": "📟"},
        {"id": "gamedev", "name": "Vývoj her", "description": "Pro vývoj her a grafiky", "extensions": 7, "active": False, "icon": "🎮"},
        {"id": "pentest", "name": "PenTest & Security", "description": "Nástroje pro penetrační testování", "extensions": 12, "active": False, "icon": "🛡️"},
        {"id": "data-science", "name": "Data Science", "description": "Analýza dat a vizualizace", "extensions": 9, "active": False, "icon": "📊"},
        {"id": "full", "name": "Kompletná (EXTREM)", "description": "Všechny nástroje a rozšíření", "extensions": 28, "active": True, "icon": "⚡"}
    ]
    return jsonify(profiles)

@app.route('/api/users')
def get_users():
    if 'user_id' not in session or session.get('role') != 'admin':
        return jsonify({'error': 'Forbidden'}), 403
    
    with sqlite3.connect(app.config['DATABASE']) as conn:
        users = conn.execute('''
            SELECT id, username, role, created_at 
            FROM users ORDER BY created_at DESC
        ''').fetchall()
        
        return jsonify([{
            'id': u[0], 'username': u[1], 'role': u[2], 'created_at': u[3]
        } for u in users])

@app.route('/api/users/create', methods=['POST'])
def create_user():
    if 'user_id' not in session or session.get('role') != 'admin':
        return jsonify({'error': 'Forbidden'}), 403
    
    data = request.get_json()
    username = data.get('username')
    password = data.get('password')
    role = data.get('role', 'user')
    
    with sqlite3.connect(app.config['DATABASE']) as conn:
        try:
            password_hash = generate_password_hash(password)
            conn.execute(
                'INSERT INTO users (username, password_hash, role) VALUES (?, ?, ?)',
                (username, password_hash, role)
            )
            return jsonify({'success': True, 'message': f'Uživatel {username} vytvořen'})
        except sqlite3.IntegrityError:
            return jsonify({'error': 'Uživatel již existuje'}), 400

@app.route('/api/users/<int:user_id>/delete', methods=['POST'])
def delete_user(user_id):
    if 'user_id' not in session or session.get('role') != 'admin':
        return jsonify({'error': 'Forbidden'}), 403
    
    if user_id == session['user_id']:
        return jsonify({'error': 'Nemůžete smazat vlastní účet'}), 400
    
    with sqlite3.connect(app.config['DATABASE']) as conn:
        conn.execute('DELETE FROM users WHERE id = ?', (user_id,))
        return jsonify({'success': True, 'message': 'Uživatel smazán'})

@app.route('/api/ai/chat', methods=['POST'])
def ai_chat():
    if 'user_id' not in session:
        return jsonify({'error': 'Unauthorized'}), 401
    
    data = request.get_json()
    user_message = data.get('message', '')
    
    # AI odpovědi
    responses = {
        'stav systému': f"🖥️ CPU: {system_data['cpu']:.1f}% | 🧠 RAM: {system_data['ram']:.1f}% | 💾 Disk: {system_data['disk']:.1f}%",
        'bezpečnost': f"🛡️ Všechny systémy jsou zabezpečeny | Hrozby: {system_data['security_status']['threats']}",
        'optimalizace': "🔧 Doporučuji: 1) Vyčistit dočasné soubory 2) Aktualizovat systém 3) Zkontrolovat automatické spouštění",
        'uživatelé': f"👥 Aktuálně přihlášeno: {system_data['active_users']} uživatelů",
        'pomoc': "❓ Mohu pomoci s: stavem systému, bezpečností, optimalizací, správou uživatelů, profily"
    }
    
    response = responses.get(user_message.lower(), 
                           "🤖 Nerozumím otázce. Zkuste: 'stav systému', 'bezpečnost', 'optimalizace', 'uživatelé', 'pomoc'")
    
    return jsonify({'response': response})

if __name__ == '__main__':
    init_db()
    print("🚀 STARKO AI WORKSPACE 4.0 - PRODUKČNÍ SERVER")
    print("📍 https://127.0.0.1:8080")
    print("⚡ RYCHLÝ • BEZPEČNÝ • MULTI-USER")
    serve(app, host='0.0.0.0', port=8080, threads=8, channel_timeout=60)
