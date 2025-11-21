#!/bin/bash
echo "🚀 Starko AI Workspace - Production Mode"

# Volba 1: Waitress (doporučeno pro Windows)
python web_gui/wsgi.py

# Volba 2: Gunicorn (pro Linux)
# gunicorn -w 4 -b 0.0.0.0:8080 web_gui.wsgi:app

# Volba 3: S produkční konfigurací
# export DEBUG=False && python web_gui/wsgi.py