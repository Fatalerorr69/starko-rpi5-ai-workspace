# 🚀 Starko AI Workspace - Aktualizace na verzi 4.0

## 📋 Přehled změn

### 🎯 Nový systém profilů
- **7 specializovaných profilů** pro různé typy projektů
- **Automatické přepínání** konfigurace a rozšíření
- **Webové rozhraní** pro správu profilů

### 🎨 Dostupné profily:
1. **minimal** - Základní nástroje
2. **python** - Python vývoj
3. **ai-ml** - AI a strojové učení  
4. **web** - Webový vývoj
5. **iot** - IoT a Raspberry Pi
6. **game** - Vývoj her
7. **full** - Všechny nástroje

### 🔧 Nové funkce
- **Správce profilů** - `python scripts/profile_manager.py`
- **Aktualizované Web GUI** s podporou profilů
- **Nové VS Code téma** - Starko Dark Pro
- **Vylepšený project manager** s podporou profilů

## 🚀 Rychlý start po aktualizaci

### 1. Spuštění Web GUI
```bash
python web_gui/app.py
# Navštivte: http://localhost:8080
```

### 2. Správa profilů
```bash
# Seznam profilů
python scripts/profile_manager.py list

# Přepnutí na AI profil
python scripts/profile_manager.py switch --profile ai-ml

# Aktuální profil
python scripts/profile_manager.py active
```

### 3. Vytvoření projektu s profilem
```bash
python projects/project_manager.py create --name muj-projekt --profile ai-ml
```

## 📊 Webové rozhraní

Nové Web GUI obsahuje:
- **Dashboard** s přehledem systémových zdrojů
- **Správu profilů** - přepínání kliknutím
- **Informace o workspace** - statistiky a metriky

## 🔄 Rollback (obnovení)

Pokud potřebujete obnovit původní verzi:
```bash
# Záloha je uložena v: /c/Users/Fatal/Desktop/VScode/RPI5/starko-rpi5-ai-workspace/backup_20251121_162024
cp -r /c/Users/Fatal/Desktop/VScode/RPI5/starko-rpi5-ai-workspace/backup_20251121_162024/* ./
```

## 📝 Poznámky k aktualizaci

- **Existující projekty** zůstávají nedotčené
- **VS Code nastavení** bylo aktualizováno
- **Web GUI** byl kompletně přepsán
- **Nové adresáře**: `profiles/`, `themes/`, `icons/`

---

**Starko AI Workspace 4.0**  
Aktualizováno: 2025-11-21 16:20:36

*Tato aktualizace přidává pokročilý systém profilů pro lepší přizpůsobení workspace vašim potřebám.*
