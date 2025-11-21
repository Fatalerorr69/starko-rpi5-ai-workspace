#!/bin/bash
# Starko Network Monitor

INTERFACE=${1:-eth0}
LOG_FILE="network_traffic_$(date +%Y%m%d_%H%M%S).log"

echo "Starko Network Monitor started on $INTERFACE"
echo "Logging to: $LOG_FILE"

# Function to monitor traffic
monitor_traffic() {
    while true; do
        TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
        RX_BYTES=$(cat /sys/class/net/$INTERFACE/statistics/rx_bytes)
        TX_BYTES=$(cat /sys/class/net/$INTERFACE/statistics/tx_bytes)
        
        echo "$TIMESTAMP - RX: $RX_BYTES bytes | TX: $TX_BYTES bytes" >> "$LOG_FILE"
        sleep 5
    done
}

# Function to capture packets
capture_packets() {
    if command -v tcpdump &> /dev/null; then
        echo "Starting packet capture..."
        tcpdump -i $INTERFACE -w "capture_$(date +%Y%m%d_%H%M%S).pcap"
    else
        echo "tcpdump not found. Install with: sudo apt install tcpdump"
    fi
}

case "${2:-monitor}" in
    "monitor")
        monitor_traffic
        ;;
    "capture")
        capture_packets
        ;;
    "analyze")
        if [ -f "$3" ]; then
            tshark -r "$3" -q -z conv,tcp
        else
            echo "Please provide pcap file: $0 $1 analyze file.pcap"
        fi
        ;;
    *)
        echo "Usage: $0 <interface> [monitor|capture|analyze]"
        echo "Examples:"
        echo "  $0 eth0 monitor        # Monitor traffic"
        echo "  $0 eth0 capture        # Capture packets"
        echo "  $0 eth0 analyze file.pcap # Analyze pcap"
        ;;
esac
