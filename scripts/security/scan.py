#!/usr/bin/env python3
"""
Bezpečnostní skenování systému
"""
import os
import hashlib
import datetime

def security_scan():
    print("🛡️ Spouštím bezpečnostní sken...")
    
    # Kontrola podezřelých souborů
    suspicious_extensions = ['.exe', '.bat', '.sh', '.py', '.js']
    suspicious_files = []
    
    for root, dirs, files in os.walk('.'):
        for file in files:
            if any(file.endswith(ext) for ext in suspicious_extensions):
                file_path = os.path.join(root, file)
                suspicious_files.append({
                    'path': file_path,
                    'size': os.path.getsize(file_path),
                    'modified': datetime.datetime.fromtimestamp(os.path.getmtime(file_path))
                })
    
    # Kontrola oprávnění
    permission_issues = []
    important_dirs = ['config', 'database', 'profiles']
    
    for dir_path in important_dirs:
        if os.path.exists(dir_path):
            try:
                # Zkontrolovat, zda jsou adresáře zabezpečené
                if oct(os.stat(dir_path).st_mode)[-3:] != '700':
                    permission_issues.append(dir_path)
            except:
                pass
    
    return {
        'suspicious_files_found': len(suspicious_files),
        'permission_issues': permission_issues,
        'scan_time': datetime.datetime.now().isoformat(),
        'status': 'completed'
    }

if __name__ == '__main__':
    result = security_scan()
    print(f"🔍 Nalezeno {result['suspicious_files_found']} podezřelých souborů")
    print(f"⚠️  {len(result['permission_issues'])} problémů s oprávněními")