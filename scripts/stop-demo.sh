#!/bin/bash

#==============================================
# FlowServer Demo - Stop Script
#==============================================
# Stops all demo components
#==============================================

echo "=========================================="
echo "FlowServer Demo - Stopping"
echo "=========================================="

PID_DIR="/tmp/flowserver-demo"

# Function to stop a process
stop_process() {
    local name=$1
    local pid_file="$PID_DIR/$2.pid"
    
    if [ -f "$pid_file" ]; then
        pid=$(cat "$pid_file")
        if kill -0 $pid 2>/dev/null; then
            kill $pid 2>/dev/null
            sleep 1
            if kill -0 $pid 2>/dev/null; then
                kill -9 $pid 2>/dev/null
            fi
            echo "✓ Stopped $name (PID: $pid)"
        else
            echo "  $name already stopped"
        fi
        rm -f "$pid_file"
    else
        echo "  No PID file for $name"
    fi
}

# Stop FlowServer jobs
echo ""
echo "Stopping FlowServer jobs..."
flowcli job stop ecommerce-orders 2>/dev/null || echo "  (Job not running)"
flowcli job stop iot-sensors-csv 2>/dev/null || echo "  (Job not running)"

# Stop data generators
echo ""
echo "Stopping data generators..."
stop_process "E-Commerce generator" "order-generator"
stop_process "IoT generator" "iot-generator"

# Stop dashboard APIs
echo ""
echo "Stopping dashboard APIs..."
stop_process "E-Commerce API" "ecommerce-api"
stop_process "IoT API" "iot-api"

# Stop web servers
echo ""
echo "Stopping web servers..."
stop_process "E-Commerce web server" "ecom-web"
stop_process "IoT web server" "iot-web"

echo ""
echo "=========================================="
echo "✓ All services stopped"
echo "=========================================="
echo ""
