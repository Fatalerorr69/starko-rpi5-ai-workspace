#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
SPRÁVCE PROFILŮ STARKO AI WORKSPACE
"""

import json
import os
import shutil
import argparse
from pathlib import Path
import subprocess

class ProfileManager:
    def __init__(self, workspace_root: str = "."):
        self.workspace_root = Path(workspace_root)
        self.profiles_file = self.workspace_root / "profiles" / "profiles.json"
        self.vscode_dir = self.workspace_root / ".vscode"
        self.load_profiles()
    
    def load_profiles(self):
        """Načte konfiguraci profilů"""
        with open(self.profiles_file, 'r') as f:
            self.profiles_data = json.load(f)
    
    def save_profiles(self):
        """Uloží konfiguraci profilů"""
        with open(self.profiles_file, 'w') as f:
            json.dump(self.profiles_data, f, indent=2)
    
    def list_profiles(self):
        """Zobrazí seznam dostupných profilů"""
        print("🎯 DOSTUPNÉ PROFILY STARKO AI WORKSPACE:")
        print("=" * 50)
        
        for profile_id, profile_data in self.profiles_data['profiles'].items():
            active_indicator = " ✅" if profile_id == self.profiles_data['active_profile'] else ""
            print(f"  {profile_id:<12} - {profile_data['name']}{active_indicator}")
            print(f"     {profile_data['description']}")
            print(f"     Rozšíření: {len(profile_data['extensions'])}")
            print()
    
    def switch_profile(self, profile_id: str, install_extensions: bool = True):
        """Přepne na zvolený profil"""
        if profile_id not in self.profiles_data['profiles']:
            print(f"❌ Profil '{profile_id}' neexistuje!")
            return False
        
        profile = self.profiles_data['profiles'][profile_id]
        
        print(f"🔄 Přepínám na profil: {profile['name']}")
        
        # Aktualizace aktivního profilu
        self.profiles_data['active_profile'] = profile_id
        self.save_profiles()
        
        # Aktualizace VS Code settings
        self.update_vscode_settings(profile)
        
        # Instalace rozšíření
        if install_extensions:
            self.install_profile_extensions(profile)
        
        print(f"✅ Profil '{profile['name']}' byl aktivován!")
        return True
    
    def update_vscode_settings(self, profile):
        """Aktualizuje VS Code nastavení podle profilu"""
        settings_file = self.vscode_dir / "settings.json"
        
        if not settings_file.exists():
            print("❌ Soubor settings.json neexistuje!")
            return
        
        with open(settings_file, 'r') as f:
            settings = json.load(f)
        
        # Aktualizace nastavení z profilu
        if 'settings' in profile:
            settings.update(profile['settings'])
        
        # Přidání starko specifických nastavení
        settings['starko.profile'] = self.profiles_data['active_profile']
        settings['starko.version'] = '4.0.0'
        
        with open(settings_file, 'w') as f:
            json.dump(settings, f, indent=2)
        
        print("✅ VS Code nastavení aktualizováno")
    
    def install_profile_extensions(self, profile):
        """Nainstaluje rozšíření pro profil"""
        if 'extensions' not in profile or not profile['extensions']:
            print("ℹ️  Žádná rozšíření k instalaci")
            return
        
        print(f"📦 Instaluji {len(profile['extensions'])} rozšíření...")
        
        installed = 0
        failed = 0
        
        for extension in profile['extensions']:
            try:
                result = subprocess.run([
                    'code', '--install-extension', extension
                ], capture_output=True, text=True, timeout=120)
                
                if result.returncode == 0:
                    print(f"   ✅ {extension}")
                    installed += 1
                else:
                    print(f"   ❌ {extension}")
                    failed += 1
                    
            except subprocess.TimeoutExpired:
                print(f"   ⏰ {extension} (timeout)")
                failed += 1
            except Exception as e:
                print(f"   ❌ {extension} ({e})")
                failed += 1
        
        print(f"📊 Výsledek: {installed} úspěšných, {failed} chyb")
    
    def create_custom_profile(self, profile_id: str, name: str, description: str, 
                            extensions: list, settings: dict):
        """Vytvoří vlastní profil"""
        if profile_id in self.profiles_data['profiles']:
            print(f"❌ Profil '{profile_id}' již existuje!")
            return False
        
        self.profiles_data['profiles'][profile_id] = {
            'name': name,
            'description': description,
            'extensions': extensions,
            'settings': settings
        }
        
        self.save_profiles()
        print(f"✅ Vlastní profil '{name}' vytvořen!")
        return True
    
    def get_active_profile(self):
        """Získá aktivní profil"""
        active_id = self.profiles_data['active_profile']
        return active_id, self.profiles_data['profiles'][active_id]

def main():
    parser = argparse.ArgumentParser(description="Správce profilů Starko AI Workspace")
    parser.add_argument("action", nargs="?", choices=["list", "switch", "active", "create"], help="Akce")
    parser.add_argument("--profile", help="ID profilu pro přepnutí")
    parser.add_argument("--name", help="Název vlastního profilu")
    parser.add_argument("--description", help="Popis vlastního profilu")
    parser.add_argument("--no-extensions", action="store_true", help="Neinstalovat rozšíření")
    
    args = parser.parse_args()
    manager = ProfileManager()
    
    try:
        if args.action == "list":
            manager.list_profiles()
        elif args.action == "switch":
            if not args.profile:
                print("❌ Zadejte --profile PROFILE_ID")
                return
            manager.switch_profile(args.profile, not args.no_extensions)
        elif args.action == "active":
            active_id, profile = manager.get_active_profile()
            print(f"✅ Aktivní profil: {profile['name']} ({active_id})")
        elif args.action == "create":
            if not all([args.profile, args.name, args.description]):
                print("❌ Pro vytvoření profilu zadejte --profile, --name a --description")
                return
            # Pro zjednodušení použijeme rozšíření z full profilu
            base_profile = manager.profiles_data['profiles']['full']
            manager.create_custom_profile(
                args.profile, args.name, args.description,
                base_profile['extensions'], base_profile['settings']
            )
        else:
            manager.list_profiles()
            print("\nPříklady použití:")
            print("  python scripts/profile_manager.py list")
            print("  python scripts/profile_manager.py switch --profile python")
            print("  python scripts/profile_manager.py active")
            
    except Exception as e:
        print(f"❌ Chyba: {e}")

if __name__ == "__main__":
    main()
