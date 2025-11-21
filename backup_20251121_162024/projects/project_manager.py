#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
AKTUALIZOVANÝ SPRÁVCE PROJEKTŮ STARKO AI WORKSPACE 4.0
"""

import os
import json
import argparse
from pathlib import Path
from datetime import datetime

class StarkoProjectManager:
    def __init__(self, workspace_root: str = "."):
        self.workspace_root = Path(workspace_root)
        self.projects_dir = self.workspace_root / "projects"
        
    def create_project(self, project_name: str, project_type: str = "standard", profile: str = None):
        """Vytvoří nový projekt s podporou profilů"""
        project_path = self.projects_dir / project_name
        
        if project_path.exists():
            print(f"❌ Projekt '{project_name}' již existuje!")
            return False
        
        try:
            # Načtení aktuálního profilu
            if not profile:
                try:
                    profiles_file = self.workspace_root / "profiles" / "profiles.json"
                    with open(profiles_file, 'r') as f:
                        profiles_data = json.load(f)
                        profile = profiles_data.get('active_profile', 'full')
                except:
                    profile = 'full'
            
            # Vytvoření struktury
            (project_path / "src").mkdir(parents=True)
            (project_path / "tests").mkdir()
            (project_path / "docs").mkdir()
            (project_path / "config").mkdir()
            (project_path / "data").mkdir()
            
            # Hlavní soubor
            main_content = f'''#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
PROJEKT: {project_name}
TYP: {project_type}
PROFIL: {profile}
STARKO AI WORKSPACE 4.0 - {datetime.now().year}
"""

import os
import sys
from pathlib import Path

def main():
    """Hlavní funkce projektu"""
    print("🚀 Vítejte v projektu {project_name}!")
    print(f"📍 Starko AI Workspace 4.0")
    print(f"🎯 Typ: {project_type}")
    print(f"🔧 Profil: {profile}")
    
    # TODO: Implementujte svůj kód zde
    
    print("✅ Projekt úspěšně spuštěn!")

if __name__ == "__main__":
    main()
'''
            
            with open(project_path / "src" / "main.py", "w") as f:
                f.write(main_content)
            
            # Konfigurace projektu
            config = {
                "project_name": project_name,
                "type": project_type,
                "profile": profile,
                "version": "1.0.0",
                "created": datetime.now().isoformat(),
                "starko_version": "4.0.0",
                "author": "Starko AI Workspace"
            }
            
            with open(project_path / "config" / "project.json", "w") as f:
                json.dump(config, f, indent=2)
            
            # README
            readme_content = f'''# {project_name}

Projekt vytvořený pomocí **Starko AI Workspace 4.0**.

## 🎯 Profil
Tento projekt byl vytvořen s profilem: **{profile}**

## 🚀 Spuštění

\`\`\`bash
python src/main.py
\`\`\`

## 📁 Struktura

- `src/` - Zdrojové kódy
- `tests/` - Testy
- `docs/` - Dokumentace  
- `config/` - Konfigurace
- `data/` - Data projektu

---
*Vytvořeno: {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}*
*Starko AI Workspace 4.0 - {profile} profile*
'''
            
            with open(project_path / "README.md", "w") as f:
                f.write(readme_content)
            
            print(f"✅ Projekt '{project_name}' vytvořen!")
            print(f"📍 Cesta: {project_path}")
            print(f"🎯 Profil: {profile}")
            print(f"🚀 Verze: Starko AI Workspace 4.0")
            return True
            
        except Exception as e:
            print(f"❌ Chyba při vytváření projektu: {e}")
            return False

def main():
    parser = argparse.ArgumentParser(description="Aktualizovaný správce projektů Starko AI Workspace 4.0")
    parser.add_argument("action", choices=["create", "list", "info"])
    parser.add_argument("--name", help="Název projektu")
    parser.add_argument("--type", default="standard", help="Typ projektu")
    parser.add_argument("--profile", help="Profil projektu")
    
    args = parser.parse_args()
    manager = StarkoProjectManager()
    
    if args.action == "create":
        if not args.name:
            print("❌ Zadejte název projektu: --name NAZEV")
            return
        manager.create_project(args.name, args.type, args.profile)
    elif args.action == "list":
        print("📂 Seznam projektů:")
        projects_dir = Path("projects")
        if projects_dir.exists():
            for project in projects_dir.iterdir():
                if project.is_dir():
                    print(f"  - {project.name}")
    elif args.action == "info":
        print("🤖 Starko AI Project Manager 4.0")
        print("Použití: python projects/project_manager.py create --name NAZEV --type TYP --profile PROFIL")

if __name__ == "__main__":
    main()
