#!/bin/bash
# Rychlý bezpečnostní scan

echo "🔍 Starko Quick Security Scan"
echo "=============================="

# Zkontrolujte dostupné nástroje
tools=("nmap" "python3" "sqlmap" "aircrack-ng")

for tool in "${tools[@]}"; do
    if command -v $tool &> /dev/null; then
        echo "✅ $tool je nainstalován"
    else
        echo "❌ $tool není nainstalován"
    fi
done

echo ""
echo "📋 Pro použití snippetů:"
echo "   - Napište 'burpscan' a stiskněte Tab pro Burp Suite"
echo "   - Napište 'sqli' a stiskněte Tab pro SQL injection test"
echo "   - Napište 'wifi-audit' a stiskněte Tab pro wireless audit"
