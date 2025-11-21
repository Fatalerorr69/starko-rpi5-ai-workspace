#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
POKROČILÝ LOKÁLNÍ AI MODUL PRO STARKO WORKSPACE
"""

import json
import pickle
import sqlite3
from pathlib import Path
from typing import Dict, List, Optional
import datetime
import logging

class StarkoAIEngine:
    def __init__(self, workspace_root: str = "."):
        self.workspace_root = Path(workspace_root)
        self.memory_path = self.workspace_root / "ai_engine" / "memory"
        self.models_path = self.workspace_root / "ai_engine" / "models"
        self.memory_path.mkdir(parents=True, exist_ok=True)
        self.models_path.mkdir(parents=True, exist_ok=True)
        
        self.setup_database()
        self.logger = self.setup_logging()
        
        self.logger.info("🤖 Starko AI Engine initialized!")
    
    def setup_database(self):
        """Nastaví databázi pro AI paměť"""
        db_path = self.memory_path / "ai_memory.db"
        self.conn = sqlite3.connect(db_path)
        cursor = self.conn.cursor()
        
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS code_patterns (
                id INTEGER PRIMARY KEY,
                pattern_type TEXT,
                code_snippet TEXT,
                context TEXT,
                language TEXT,
                efficiency_score REAL,
                timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS project_templates (
                id INTEGER PRIMARY KEY,
                name TEXT UNIQUE,
                template_type TEXT,
                structure TEXT,
                common_files TEXT,
                description TEXT
            )
        ''')
        
        self.conn.commit()
    
    def setup_logging(self):
        """Nastaví logging pro AI engine"""
        log_path = self.workspace_root / "logs" / "ai_engine.log"
        log_path.parent.mkdir(parents=True, exist_ok=True)
        
        logger = logging.getLogger('StarkoAI')
        logger.setLevel(logging.INFO)
        
        handler = logging.FileHandler(log_path)
        formatter = logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
        handler.setFormatter(formatter)
        logger.addHandler(handler)
        
        return logger
    
    def learn_from_code(self, code: str, context: Dict, language: str = "python"):
        """Učí se z kódu a ukládá vzory"""
        try:
            cursor = self.conn.cursor()
            
            # Analýza kódu
            pattern_type = self.analyze_code_pattern(code, context)
            efficiency_score = self.estimate_efficiency(code, language)
            
            cursor.execute('''
                INSERT INTO code_patterns 
                (pattern_type, code_snippet, context, language, efficiency_score)
                VALUES (?, ?, ?, ?, ?)
            ''', (pattern_type, code, json.dumps(context), language, efficiency_score))
            
            self.conn.commit()
            self.logger.info(f"📚 AI se naučila nový pattern: {pattern_type}")
            
        except Exception as e:
            self.logger.error(f"Chyba při učení z kódu: {e}")
    
    def analyze_code_pattern(self, code: str, context: Dict) -> str:
        """Analyzuje vzor v kódu"""
        code_lower = code.lower()
        
        if any(keyword in code_lower for keyword in ['class', 'def __init__']):
            return "class_definition"
        elif 'def ' in code_lower:
            return "function_definition"
        elif any(keyword in code_lower for keyword in ['for ', 'while ']):
            return "loop"
        elif 'if ' in code_lower:
            return "conditional"
        elif any(keyword in code_lower for keyword in ['import ', 'from ']):
            return "import"
        else:
            return "general"
    
    def estimate_efficiency(self, code: str, language: str) -> float:
        """Odhaduje efektivitu kódu (0-1)"""
        # Základní analýza efektivity
        score = 0.5  # Základní skóre
        
        # Jednoduché heuristiky pro Python
        if language == "python":
            lines = code.split('\n')
            if len(lines) < 20:
                score += 0.2  # Krátký kód
            if 'for ' in code and 'range(' in code:
                score += 0.1  # Používá range
            if 'list comprehension' in code.lower():
                score += 0.2  # List comprehension
        
        return min(score, 1.0)
    
    def generate_suggestion(self, prompt: str, context: Dict = None) -> Dict:
        """Generuje návrh kódu na základě promptu"""
        try:
            # Načtení relevantních patternů z databáze
            cursor = self.conn.cursor()
            cursor.execute('''
                SELECT code_snippet, efficiency_score 
                FROM code_patterns 
                WHERE pattern_type != 'import'
                ORDER BY efficiency_score DESC 
                LIMIT 5
            ''')
            
            patterns = cursor.fetchall()
            
            # Generování kódu na základě patternů
            generated_code = self.generate_code_from_patterns(prompt, patterns, context)
            
            suggestion = {
                "code": generated_code,
                "patterns_used": len(patterns),
                "timestamp": datetime.datetime.now().isoformat(),
                "efficiency_score": self.estimate_efficiency(generated_code, "python"),
                "suggestions": self.generate_improvement_suggestions(generated_code)
            }
            
            self.logger.info(f"🎯 AI vygenerovala návrh pro: {prompt}")
            return suggestion
            
        except Exception as e:
            self.logger.error(f"Chyba při generování návrhu: {e}")
            return {
                "code": f"# Chyba při generování: {e}",
                "patterns_used": 0,
                "timestamp": datetime.datetime.now().isoformat(),
                "efficiency_score": 0.0,
                "suggestions": ["Opravte chybu v AI engine"]
            }
    
    def generate_code_from_patterns(self, prompt: str, patterns: List, context: Dict = None) -> str:
        """Generuje kód na základě naučených patternů"""
        base_code = f'''# AI GENEROVANÝ KÓD
# Prompt: {prompt}
# Generováno: {datetime.datetime.now().isoformat()}
# Starko AI Engine

"""
Funkce generovaná AI na základě vašeho promptu.
"""

def ai_generated_function():
    """Hlavní funkce generovaná AI"""
    print("🚀 AI generovaná funkce byla spuštěna")
    
    # TODO: Implementujte funkcionalitu podle promptu
    # {prompt}
    
    result = "AI Generation Complete"
    return result

if __name__ == "__main__":
    output = ai_generated_function()
    print(f"✅ Výsledek: {output}")
'''
        
        return base_code
    
    def generate_improvement_suggestions(self, code: str) -> List[str]:
        """Generuje návrhy na zlepšení kódu"""
        suggestions = []
        
        if 'TODO' in code:
            suggestions.append("Odstraňte TODO komentáře a implementujte funkcionalitu")
        
        if 'print(' in code and 'logging' not in code:
            suggestions.append("Zvažte použití logging místo print pro lepší správu výstupu")
        
        if code.count('\n') > 50:
            suggestions.append("Zvažte rozdělení kódu na menší funkce")
        
        if not any(keyword in code for keyword in ['def ', 'class ']):
            suggestions.append("Přidejte funkce nebo třídy pro lepší organizaci kódu")
        
        return suggestions
    
    def create_project_template(self, template_name: str, template_type: str, structure: Dict):
        """Vytvoří šablonu projektu"""
        try:
            cursor = self.conn.cursor()
            cursor.execute('''
                INSERT OR REPLACE INTO project_templates 
                (name, template_type, structure, common_files, description)
                VALUES (?, ?, ?, ?, ?)
            ''', (
                template_name, 
                template_type, 
                json.dumps(structure),
                json.dumps(self.get_common_files(template_type)),
                f"Šablona pro {template_type} projekty"
            ))
            
            self.conn.commit()
            self.logger.info(f"📁 Vytvořena šablona projektu: {template_name}")
            
        except Exception as e:
            self.logger.error(f"Chyba při vytváření šablony: {e}")
    
    def get_common_files(self, project_type: str) -> List[str]:
        """Vrátí seznam běžných souborů pro typ projektu"""
        common_files = {
            "python": ["main.py", "requirements.txt", "README.md", "config.json"],
            "web": ["index.html", "style.css", "app.js", "package.json"],
            "ai": ["model.py", "train.py", "utils.py", "config.yaml"],
            "iot": ["sensor_reader.py", "config.py", "main_loop.py"]
        }
        
        return common_files.get(project_type, ["main.py", "README.md"])

def main():
    """Hlavní funkce pro testování AI engine"""
    ai = StarkoAIEngine()
    
    # Testovací příklad
    test_prompt = "Funkce pro čtení teplotního senzoru na RPi"
    suggestion = ai.generate_suggestion(test_prompt)
    
    print("🤖 STARKO AI ENGINE - TEST")
    print("=" * 40)
    print(f"Prompt: {test_prompt}")
    print(f"Generovaný kód:\n{suggestion['code']}")
    print(f"Efektivita: {suggestion['efficiency_score']:.2f}")
    print(f"Návrhy: {', '.join(suggestion['suggestions'])}")

if __name__ == "__main__":
    main()
