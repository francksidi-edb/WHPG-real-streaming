#!/bin/bash

#==============================================
# FlowServer Demo - Start Script
#==============================================
# Starts all demo components:
# - Data generators (E-Commerce & IoT)
# - FlowServer jobs
# - Dashboard APIs
# - Web servers
#==============================================

set -e

# Default configuration
ECOM_RATE=50
IOT_RATE=20
ECOM_TOTAL=0
IOT_TOTAL=0

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --ecom-rate)
            ECOM_RATE="$2"
            shift 2
            ;;
        --iot-rate)
            IOT_RATE="$2"
            shift 2
            ;;
        --ecom-total)
            ECOM_TOTAL="$2"
            shift 2
            ;;
        --iot-total)
            IOT_TOTAL="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--ecom-rate N] [--iot-rate N] [--ecom-total N] [--iot-total N]"
            exit 1
            ;;
    esac
done

echo "=========================================="
echo "FlowServer Demo - Starting"
echo "=========================================="
echo "Configuration:"
echo "  E-Commerce rate: $ECOM_RATE orders/sec"
echo "  IoT rate: $IOT_RATE readings/sec"
echo "  E-Commerce total: $ECOM_TOTAL (0=unlimited)"
echo "  IoT total: $IOT_TOTAL (0=unlimited)"
echo ""

# Stop any existing processes
echo "Stopping existing processes..."
./scripts/stop-demo.sh 2>/dev/null || true

# Create PID file directory
mkdir -p /tmp/flowserver-demo

# Start data generators
echo ""
echo "Starting data generators..."

cd generators
nohup ./order-generator -rate $ECOM_RATE -max-messages $ECOM_TOTAL > /tmp/flowserver-demo/order-generator.log 2>&1 &
echo $! > /tmp/flowserver-demo/order-generator.pid
echo "✓ E-Commerce generator started (PID: $!)"

nohup ./iot-generator -rate $IOT_RATE -max-messages $IOT_TOTAL > /tmp/flowserver-demo/iot-generator.log 2>&1 &
echo $! > /tmp/flowserver-demo/iot-generator.pid
echo "✓ IoT generator started (PID: $!)"
cd ..

# Wait for generators to produce some data
echo ""
echo "Waiting for data generation..."
sleep 3

# Start FlowServer jobs
echo ""
echo "Starting FlowServer jobs..."

flowcli job start ecommerce-orders 2>/dev/null || echo "  (Job already running or needs to be submitted first)"
flowcli job start iot-sensors-csv 2>/dev/null || echo "  (Job already running or needs to be submitted first)"

echo "✓ FlowServer jobs started"

# Start dashboard APIs
echo ""
echo "Starting dashboard APIs..."

cd dashboards
nohup python3 ecommerce-api.py > /tmp/flowserver-demo/ecommerce-api.log 2>&1 &
echo $! > /tmp/flowserver-demo/ecommerce-api.pid
echo "✓ E-Commerce API started (PID: $!, Port: 5000)"

nohup python3 iot-api.py > /tmp/flowserver-demo/iot-api.log 2>&1 &
echo $! > /tmp/flowserver-demo/iot-api.pid
echo "✓ IoT API started (PID: $!, Port: 5001)"
cd ..

# Wait for APIs to start
sleep 2

# Start web servers
echo ""
echo "Starting web servers..."

cd dashboards
nohup python3 -m http.server 8666 --bind 0.0.0.0 > /tmp/flowserver-demo/ecom-web.log 2>&1 &
echo $! > /tmp/flowserver-demo/ecom-web.pid
echo "✓ E-Commerce web server started (PID: $!, Port: 8666)"

nohup python3 -m http.server 8668 --bind 0.0.0.0 > /tmp/flowserver-demo/iot-web.log 2>&1 &
echo $! > /tmp/flowserver-demo/iot-web.pid
echo "✓ IoT web server started (PID: $!, Port: 8668)"
cd ..

echo ""
echo "=========================================="
echo "✓ All services started successfully!"
echo "=========================================="
echo ""
echo "Dashboard URLs:"
echo "  E-Commerce: http://localhost:8666/ecommerce-dashboard.html"
echo "  IoT Sensors: http://localhost:8668/iot.html"
echo ""
echo "API Endpoints:"
echo "  E-Commerce API: http://localhost:5000/api/metrics"
echo "  IoT API: http://localhost:5001/api/metrics"
echo ""
echo "Check status: ./scripts/status-demo.sh"
echo "Stop demo: ./scripts/stop-demo.sh"
echo "View logs: tail -f /tmp/flowserver-demo/*.log"
echo ""
