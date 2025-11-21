# test_system.py
import psutil
import time

def test_metrics():
    try:
        cpu = psutil.cpu_percent(interval=1)
        memory = psutil.virtual_memory()
        disk = psutil.disk_usage('/')
        
        print(f"CPU: {cpu}%")
        print(f"RAM: {memory.percent}%")
        print(f"Disk: {disk.percent}%")
        print("Vše funguje správně!")
        
    except Exception as e:
        print(f"Chyba: {e}")

if __name__ == "__main__":
    test_metrics()