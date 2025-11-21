#!/usr/bin/env python
# web_gui/app.py
"""
Automatická patch verze app.py s detekcí OS a správným async_mode
- Windows -> threading
- Linux/WSL/RPi -> eventlet (pokud dostupné), fallback na threading
"""

import os
import sys
import platform

# ---------- AUTOMATICKÁ DETEKCE ROOT ----------
current_file = os.path.abspath(__file__)
workspace_root = os.path.dirname(os.path.dirname(current_file))  # kořen projektu
if workspace_root not in sys.path:
    sys.path.insert(0, workspace_root)

# ---------- Flask + SocketIO ----------
from flask import Flask
from flask_socketio import SocketIO

# ---------- Inicializace Flask ----------
app = Flask(__name__, template_folder=os.path.join(os.path.dirname(__file__), "templates"))

# ---------- Detekce async_mode ----------
async_mode = None
if platform.system() == "Windows":
    async_mode = "threading"
else:
    try:
        import eventlet  # noqa
        async_mode = "eventlet"
    except ImportError:
        async_mode = "threading"

print(f"[INFO] Detekováno OS: {platform.system()}, použit async_mode: {async_mode}")
socketio = SocketIO(app, async_mode=async_mode)

# ---------- Blueprints ----------
try:
    from web_gui.routes.dashboard import bp as dashboard_bp
    from web_gui.routes.system import bp as system_bp
    from web_gui.routes.files import bp as files_bp
    from web_gui.routes.ai import bp as ai_bp
    from web_gui.routes.tools import bp as tools_bp
    from web_gui.routes.shell import bp as shell_bp
    from web_gui.routes.servers import bp as servers_bp
    from web_gui.routes.android import bp as android_bp
    from web_gui.routes.waydroid import bp as waydroid_bp
except ModuleNotFoundError as e:
    print(f"[WARNING] Blueprint load failed: {e}")

for bp_var in ['dashboard_bp','system_bp','files_bp','ai_bp','tools_bp','shell_bp','servers_bp','android_bp','waydroid_bp']:
    bp = globals().get(bp_var)
    if bp:
        app.register_blueprint(bp, url_prefix='/')

# ---------- SocketIO Namespaces ----------
try:
    from web_gui.ws.shell import ShellNamespace
    from web_gui.ws.logs import LogsNamespace
    from web_gui.ws.monitor import MonitorNamespace

    socketio.on_namespace(ShellNamespace('/shell'))
    socketio.on_namespace(LogsNamespace('/logs'))
    socketio.on_namespace(MonitorNamespace('/monitor'))
except ModuleNotFoundError as e:
    print(f"[WARNING] WS namespace load failed: {e}")

# ---------- Main ----------
if __name__ == "__main__":
    print(f"[INFO] Starting WebGUI at workspace root: {workspace_root}")
    socketio.run(app, host='0.0.0.0', port=5000)
