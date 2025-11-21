# web_gui/production_server.py
from flask import Flask, render_template, jsonify, request
import json
import os
import psutil
import cpuinfo
import GPUtil
from datetime import datetime

def create_app():
    app = Flask(__name__)
    app.config['SECRET_KEY'] = 'starko-ai-workspace-secret-key'

    # Database initialization
    def init_db():
        """Initialize database and required files"""
        database_dir = 'database'
        os.makedirs(database_dir, exist_ok=True)
        
        # Create basic database file
        db_file = os.path.join(database_dir, 'workspace.db')
        if not os.path.exists(db_file):
            with open(db_file, 'w') as f:
                json.dump({
                    'profiles': [],
                    'system_info': {},
                    'created_at': datetime.now().isoformat()
                }, f, indent=2)
        
        # Create default config
        config_file = os.path.join(database_dir, 'config.json')
        if not os.path.exists(config_file):
            with open(config_file, 'w') as f:
                json.dump({
                    'theme': 'dark',
                    'auto_start': False,
                    'port': 8080,
                    'host': '0.0.0.0'
                }, f, indent=2)
        
        print("✅ Database initialized")

    # Routes
    @app.route('/')
    def index():
        return render_template('index.html')

    @app.route('/api/system-info')
    def system_info():
        """Get system information"""
        try:
            # CPU Info
            cpu_info = cpuinfo.get_cpu_info()
            cpu_usage = psutil.cpu_percent(interval=1)
            
            # Memory Info
            memory = psutil.virtual_memory()
            
            # Disk Info
            disk = psutil.disk_usage('/')
            
            # GPU Info (if available)
            gpus = []
            try:
                gpus = GPUtil.getGPUs()
            except:
                pass
            
            system_data = {
                'cpu': {
                    'name': cpu_info.get('brand_raw', 'Unknown'),
                    'cores': psutil.cpu_count(logical=False),
                    'threads': psutil.cpu_count(logical=True),
                    'usage': cpu_usage,
                    'frequency': cpu_info.get('hz_actual', 'Unknown')
                },
                'memory': {
                    'total': round(memory.total / (1024**3), 2),
                    'used': round(memory.used / (1024**3), 2),
                    'free': round(memory.free / (1024**3), 2),
                    'percent': memory.percent
                },
                'disk': {
                    'total': round(disk.total / (1024**3), 2),
                    'used': round(disk.used / (1024**3), 2),
                    'free': round(disk.free / (1024**3), 2),
                    'percent': disk.percent
                },
                'gpu': [],
                'platform': {
                    'system': cpu_info.get('arch', 'Unknown'),
                    'python_version': cpu_info.get('python_version', 'Unknown')
                }
            }
            
            # Add GPU info
            for gpu in gpus:
                system_data['gpu'].append({
                    'name': gpu.name,
                    'load': gpu.load * 100,
                    'memory_total': gpu.memoryTotal,
                    'memory_used': gpu.memoryUsed,
                    'memory_free': gpu.memoryFree
                })
            
            return jsonify(system_data)
        except Exception as e:
            return jsonify({'error': str(e)}), 500

    @app.route('/api/profiles')
    def get_profiles():
        """Get available profiles"""
        profiles = []
        profiles_dir = 'profiles'
        
        if os.path.exists(profiles_dir):
            for profile in os.listdir(profiles_dir):
                if os.path.isdir(os.path.join(profiles_dir, profile)):
                    profiles.append({
                        'name': profile,
                        'path': os.path.join(profiles_dir, profile)
                    })
        
        return jsonify(profiles)

    @app.route('/api/start-profile/<profile_name>')
    def start_profile(profile_name):
        """Start a specific profile"""
        # This would contain logic to start different profiles
        return jsonify({
            'status': 'success',
            'message': f'Profile {profile_name} started',
            'profile': profile_name
        })

    @app.route('/api/scripts')
    def get_scripts():
        """Get available scripts"""
        scripts = {}
        script_categories = ['system', 'security', 'automation', 'development']
        
        for category in script_categories:
            category_dir = f'scripts/{category}'
            scripts[category] = []
            
            if os.path.exists(category_dir):
                for script in os.listdir(category_dir):
                    if script.endswith('.py'):
                        scripts[category].append({
                            'name': script[:-3],  # Remove .py extension
                            'path': os.path.join(category_dir, script)
                        })
        
        return jsonify(scripts)

    @app.route('/health')
    def health():
        return jsonify({'status': 'healthy', 'timestamp': datetime.now().isoformat()})

    return app, init_db

# Create app and init_db function
app, init_db = create_app()

if __name__ == '__main__':
    init_db()
    print("🚀 Starting Starko AI Workspace...")
    print("🌐 Server running on http://127.0.0.1:8080")
    
    from waitress import serve
    serve(app, host='0.0.0.0', port=8080, threads=6)