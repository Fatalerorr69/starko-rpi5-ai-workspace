#!/usr/bin/env python3
"""
Automatické zálohování workspace
"""
import os
import shutil
import datetime
import zipfile

def backup_workspace():
    print("💾 Spouštím zálohování workspace...")
    
    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_name = f"starko_backup_{timestamp}"
    backup_path = f"backups/{backup_name}"
    
    os.makedirs(backup_path, exist_ok=True)
    
    # Adresáře k zálohování
    backup_dirs = ['config', 'profiles', 'scripts', 'modules', 'web_gui/templates']
    
    for dir_path in backup_dirs:
        if os.path.exists(dir_path):
            dest_path = os.path.join(backup_path, dir_path)
            os.makedirs(os.path.dirname(dest_path), exist_ok=True)
            shutil.copytree(dir_path, dest_path)
    
    # Vytvořit zip archiv
    with zipfile.ZipFile(f"{backup_path}.zip", 'w') as zipf:
        for root, dirs, files in os.walk(backup_path):
            for file in files:
                file_path = os.path.join(root, file)
                arcname = os.path.relpath(file_path, backup_path)
                zipf.write(file_path, arcname)
    
    # Vyčistit původní adresář
    shutil.rmtree(backup_path)
    
    backup_size = os.path.getsize(f"{backup_path}.zip")
    
    return {
        'backup_name': f"{backup_name}.zip",
        'backup_size_mb': backup_size / 1024 / 1024,
        'timestamp': datetime.datetime.now().isoformat(),
        'status': 'success'
    }

if __name__ == '__main__':
    result = backup_workspace()
    print(f"✅ Záloha vytvořena: {result['backup_name']}")
    print(f"📦 Velikost: {result['backup_size_mb']:.1f} MB")