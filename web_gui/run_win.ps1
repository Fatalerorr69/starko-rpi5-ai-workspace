# web_gui/run_win.ps1
Set-StrictMode -Version Latest
$cwd = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $cwd
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements_web.txt
python -u app.py
