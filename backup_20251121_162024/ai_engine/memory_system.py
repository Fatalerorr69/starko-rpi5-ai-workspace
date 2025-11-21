#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
ROZŠÍŘENÝ SYSTÉM PAMĚTI PRO STARKO AI
"""

import sqlite3
import json
from pathlib import Path
from datetime import datetime

class AdvancedMemorySystem:
    def __init__(self, db_path: str = "ai_memory.db"):
        self.db_path = Path(db_path)
        self.init_database()
    
    def init_database(self):
        """Inicializuje pokročilou databázi paměti"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        # Tabulka pro vzory kódu
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS code_patterns (
                id INTEGER PRIMARY KEY,
                pattern_type TEXT,
                code_snippet TEXT,
                context TEXT,
                language TEXT,
                efficiency_score REAL,
                usage_count INTEGER DEFAULT 0,
                timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        
        # Tabulka pro chyby a řešení
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS error_solutions (
                id INTEGER PRIMARY KEY,
                error_type TEXT,
                error_message TEXT,
                solution TEXT,
                programming_language TEXT,
                occurrence_count INTEGER DEFAULT 1,
                last_occurrence DATETIME DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        
        # Tabulka pro optimalizace
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS optimizations (
                id INTEGER PRIMARY KEY,
                optimization_type TEXT,
                before_code TEXT,
                after_code TEXT,
                improvement_percent REAL,
                context TEXT
            )
        ''')
        
        conn.commit()
        conn.close()
        print("✅ Rozšířená databáze paměti inicializována")
    
    def record_error_solution(self, error_type: str, error_message: str, solution: str, language: str = "python"):
        """Zaznamená chybu a její řešení"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        # Kontrola jestli chyba již existuje
        cursor.execute('''
            SELECT id, occurrence_count FROM error_solutions 
            WHERE error_type = ? AND error_message = ?
        ''', (error_type, error_message))
        
        result = cursor.fetchone()
        
        if result:
            # Aktualizace existující chyby
            cursor.execute('''
                UPDATE error_solutions 
                SET occurrence_count = occurrence_count + 1,
                    last_occurrence = CURRENT_TIMESTAMP
                WHERE id = ?
            ''', (result[0],))
        else:
            # Nový záznam chyby
            cursor.execute('''
                INSERT INTO error_solutions 
                (error_type, error_message, solution, programming_language)
                VALUES (?, ?, ?, ?)
            ''', (error_type, error_message, solution, language))
        
        conn.commit()
        conn.close()
    
    def get_solution_for_error(self, error_message: str) -> str:
        """Najde řešení pro chybu"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute('''
            SELECT solution, occurrence_count 
            FROM error_solutions 
            WHERE error_message LIKE ? 
            ORDER BY occurrence_count DESC 
            LIMIT 1
        ''', (f'%{error_message}%',))
        
        result = cursor.fetchone()
        conn.close()
        
        if result:
            return result[0]
        else:
            return "Řešení pro tuto chybu nebylo nalezeno v paměti."

def main():
    memory = AdvancedMemorySystem()
    print("✅ Advanced Memory System je připraven")

if __name__ == "__main__":
    main()
