#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"
python3 -m venv .venv || true
source .venv/scripts/activate
pip install -r requirements_web.txt
# spustit s eventlet
python -u app.py
