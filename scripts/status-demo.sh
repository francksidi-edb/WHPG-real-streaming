#!/bin/bash

#==============================================
# FlowServer Demo - Status Script
#==============================================
# Checks status of all demo components
#==============================================

echo "=========================================="
echo "FlowServer Demo - Status Check"
echo "=========================================="
echo "Timestamp: $(date)"
echo ""

PID_DIR="/tmp/flowserver-demo"

# Function to check process status
check_process() {
    local name=$1
    local pid_file="$PID_DIR/$2.pid"
    
    if [ -f "$pid_file" ]; then
        pid=$(cat "$pid_file")
        if kill -0 $pid 2>/dev/null; then
            echo "✓ $name is running (PID: $pid)"
            return 0
        else
            echo "✗ $name is NOT running (stale PID: $pid)"
            return 1
        fi
    else
        echo "✗ $name is NOT running (no PID file)"
        return 1
    fi
}

# Check FlowServer jobs
echo "FlowServer Jobs:"
echo "----------------"
flowcli job status ecommerce-orders 2>/dev/null || echo "✗ ecommerce-orders not found"
flowcli job status iot-sensors-csv 2>/dev/null || echo "✗ iot-sensors-csv not found"
echo ""

# Check data generators
echo "Data Generators:"
echo "----------------"
check_process "E-Commerce generator" "order-generator"
check_process "IoT generator" "iot-generator"
echo ""

# Check dashboard APIs
echo "Dashboard APIs:"
echo "---------------"
check_process "E-Commerce API" "ecommerce-api"
check_process "IoT API" "iot-api"

# Test API endpoints
if curl -s http://localhost:5000/api/health > /dev/null 2>&1; then
    echo "  ✓ E-Commerce API responding on port 5000"
else
    echo "  ✗ E-Commerce API not responding on port 5000"
fi

if curl -s http://localhost:5001/api/health > /dev/null 2>&1; then
    echo "  ✓ IoT API responding on port 5001"
else
    echo "  ✗ IoT API not responding on port 5001"
fi
echo ""

# Check web servers
echo "Web Servers:"
echo "------------"
check_process "E-Commerce web server" "ecom-web"
check_process "IoT web server" "iot-web"

if curl -s http://localhost:8666 > /dev/null 2>&1; then
    echo "  ✓ E-Commerce web server responding on port 8666"
else
    echo "  ✗ E-Commerce web server not responding on port 8666"
fi

if curl -s http://localhost:8668 > /dev/null 2>&1; then
    echo "  ✓ IoT web server responding on port 8668"
else
    echo "  ✗ IoT web server not responding on port 8668"
fi
echo ""

# Check database connection and data
echo "Database Status:"
echo "----------------"
if psql -h localhost -p 5432 -U gpadmin -d albaraka -c "SELECT 1" > /dev/null 2>&1; then
    echo "✓ Database connection successful"
    
    # Get row counts
    ecom_count=$(psql -h localhost -p 5432 -U gpadmin -d albaraka -t -c "SELECT COUNT(*) FROM ecommerce_orders" 2>/dev/null | tr -d ' ')
    iot_count=$(psql -h localhost -p 5432 -U gpadmin -d albaraka -t -c "SELECT COUNT(*) FROM iot_sensor_readings" 2>/dev/null | tr -d ' ')
    
    echo "  E-Commerce orders: ${ecom_count:-0}"
    echo "  IoT readings: ${iot_count:-0}"
else
    echo "✗ Database connection failed"
fi
echo ""

# Check Kafka
echo "Kafka Status:"
echo "-------------"
if kafka-broker-api-versions --bootstrap-server localhost:9092 > /dev/null 2>&1; then
    echo "✓ Kafka broker reachable"
    
    # List topics
    topics=$(kafka-topics --list --bootstrap-server localhost:9092 2>/dev/null | grep -E "ecommerce-orders|iot-sensors-csv" | tr '\n' ', ' | sed 's/,$//')
    if [ -n "$topics" ]; then
        echo "  Topics: $topics"
    fi
else
    echo "✗ Kafka broker not reachable"
fi
echo ""

echo "=========================================="
echo "Dashboard URLs:"
echo "  http://localhost:8666/ecommerce-dashboard.html"
echo "  http://localhost:8668/iot.html"
echo "=========================================="
echo ""
