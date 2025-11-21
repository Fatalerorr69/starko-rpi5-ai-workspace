#!/usr/bin/env python3
"""
Skript pro vyčištění systému a optimalizaci
"""
import os
import shutil
import tempfile
import datetime

def cleanup_system():
    print("🧹 Spouštím systémové čištění...")
    
    # Čištění dočasných souborů
    temp_dirs = [
        tempfile.gettempdir(),
        '/tmp',
        'temp'
    ]
    
    cleaned_files = 0
    cleaned_size = 0
    
    for temp_dir in temp_dirs:
        if os.path.exists(temp_dir):
            for root, dirs, files in os.walk(temp_dir):
                for file in files:
                    try:
                        file_path = os.path.join(root, file)
                        file_size = os.path.getsize(file_path)
                        os.remove(file_path)
                        cleaned_files += 1
                        cleaned_size += file_size
                    except:
                        continue
    
    # Čištění cache
    cache_dirs = [
        os.path.expanduser('~/.cache'),
        'logs/temp'
    ]
    
    for cache_dir in cache_dirs:
        if os.path.exists(cache_dir):
            try:
                shutil.rmtree(cache_dir)
                os.makedirs(cache_dir)
            except:
                pass
    
    print(f"✅ Vyčištěno {cleaned_files} souborů ({cleaned_size/1024/1024:.1f} MB)")
    return {
        'cleaned_files': cleaned_files,
        'cleaned_size_mb': cleaned_size / 1024 / 1024,
        'timestamp': datetime.datetime.now().isoformat()
    }

if __name__ == '__main__':
    result = cleanup_system()
    print("🎉 Čištění dokončeno!")