from app import app
import os

if __name__ == "__main__":
    # Produkční nastavení
    port = int(os.environ.get('PORT', 8080))
    debug = os.environ.get('DEBUG', 'False').lower() == 'true'
    
    if debug:
        # Vývojový režim
        app.run(host='0.0.0.0', port=port, debug=True)
    else:
        # Produkční režim - použije Waitress
        from waitress import serve
        print("🚀 Starko AI Workspace - Production Server")
        print("📊 Optimalizováno pro vysoký výkon")
        serve(app, host='0.0.0.0', port=port)