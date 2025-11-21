# web_gui/core/system_info.py
"""Minimalni funkce pro získání základních informací o systému.
Tento soubor je stub — rozšíříš ho později o měření CPU, disk, teploty RPi atd.
"""
import platform
import psutil




def get_system_info():
return {
"platform": platform.platform(),
"hostname": platform.node(),
"cpu_count": psutil.cpu_count(logical=True),
"memory": psutil.virtual_memory()._asdict(),
}
