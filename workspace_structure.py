#!/usr/bin/env python3
"""
Skript pro vytvoření kompletní struktury Starko AI Workspace
"""
import os
import json
import shutil

def create_complete_structure():
    base_dirs = [
        'web_gui/templates',
        'web_gui/static/css',
        'web_gui/static/js',
        'web_gui/static/images',
        'scripts/system',
        'scripts/security',
        'scripts/development',
        'scripts/automation',
        'modules/ai',
        'modules/security',
        'modules/system',
        'modules/network',
        'profiles/StarkoPenTest',
        'profiles/StarkoDarkPro',
        'profiles/StarkoAI',
        'config',
        'logs',
        'database',
        'backups',
        'temp'
    ]
    
    for directory in base_dirs:
        os.makedirs(directory, exist_ok=True)
        print(f"✅ Vytvořeno: {directory}")

if __name__ == '__main__':
    create_complete_structure()