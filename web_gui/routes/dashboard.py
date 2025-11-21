# web_gui/routes/dashboard.py
from flask import Blueprint, render_template, jsonify
from web_gui.core import get_system_info, AIEngine


bp = Blueprint('dashboard', __name__, template_folder='../templates')


ai = AIEngine()


@bp.route('/')
def index():
info = get_system_info()
return render_template('dashboard.html', sysinfo=info)


@bp.route('/api/ai/ping')
def ai_ping():
return jsonify(ai.ping())
