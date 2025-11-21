# web_gui/ws/shell.py
# Requires Flask-SocketIO. Tento stub posila/ prijima data.
from flask_socketio import Namespace, emit


class ShellNamespace(Namespace):
def on_connect(self):
emit('shell:status', {'msg': 'connected'})


def on_disconnect(self):
print('shell client disconnected')


def on_command(self, data):
# data = {"cmd": "ls -la"}
cmd = data.get('cmd')
# V PRODUCTION: zde nutne validovat a sandboxovat prikazy
emit('shell:output', {'cmd': cmd, 'output': '[stub] command received'})
