# Prerequisites

This document outlines all prerequisites for running the FlowServer demo.

## Required Software

### 1. Apache Kafka

**Version**: 2.8.0 or higher

**Installation**:
```bash
# Download Kafka
wget https://archive.apache.org/dist/kafka/3.5.0/kafka_2.13-3.5.0.tgz
tar -xzf kafka_2.13-3.5.0.tgz
cd kafka_2.13-3.5.0

# Start ZooKeeper
bin/zookeeper-server-start.sh config/zookeeper.properties &

# Start Kafka
bin/kafka-server-start.sh config/server.properties &
```

**Verify Installation**:
```bash
kafka-broker-api-versions --bootstrap-server localhost:9092
```

### 2. WarehousePG (Greenplum Fork)

**Version**: Latest stable release

**Installation**: Follow the official WarehousePG installation guide for your platform.

**Verify Installation**:
```bash
psql -h localhost -p 5432 -U gpadmin -d postgres -c "SELECT version();"
```

**Required Configuration**:
- Port: 5432 (default)
- User: gpadmin
- Password: (as configured during installation)

### 3. FlowServer

**Installation**: Follow the official FlowServer installation guide.

**Verify Installation**:
```bash
flowcli version
```

**Required Commands**:
- `flowcli job submit <yaml>` - Submit jobs
- `flowcli job start <name>` - Start jobs
- `flowcli job stop <name>` - Stop jobs
- `flowcli job status <name>` - Check status

### 4. Go Programming Language

**Version**: 1.19 or higher

**Installation**:
```bash
# Download and install
wget https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz

# Add to PATH
export PATH=$PATH:/usr/local/go/bin
```

**Verify Installation**:
```bash
go version
```

### 5. Python 3

**Version**: 3.8 or higher

**Installation**:
```bash
# Most Linux distributions come with Python3
python3 --version

# Install pip if not present
sudo apt-get install python3-pip  # Debian/Ubuntu
sudo yum install python3-pip      # RHEL/CentOS
```

**Required Packages**:
```bash
pip install flask flask-cors psycopg2-binary --break-system-packages
```

## Network Requirements

### Required Ports

| Service | Port | Purpose |
|---------|------|---------|
| Kafka | 9092 | Message broker |
| WarehousePG | 5432 | Database |
| E-Commerce API | 5000 | Dashboard API |
| IoT API | 5001 | Dashboard API |
| E-Commerce Web | 8666 | Web dashboard |
| IoT Web | 8668 | Web dashboard |

### Firewall Configuration

Ensure these ports are accessible:
```bash
# Example for firewalld
sudo firewall-cmd --add-port=9092/tcp --permanent
sudo firewall-cmd --add-port=5432/tcp --permanent
sudo firewall-cmd --add-port=5000-5001/tcp --permanent
sudo firewall-cmd --add-port=8666/tcp --permanent
sudo firewall-cmd --add-port=8668/tcp --permanent
sudo firewall-cmd --reload
```

## System Requirements

### Minimum Hardware

- **CPU**: 4 cores
- **RAM**: 8 GB
- **Disk**: 20 GB free space
- **Network**: 1 Gbps

### Recommended Hardware

- **CPU**: 8+ cores
- **RAM**: 16+ GB
- **Disk**: 50+ GB SSD
- **Network**: 10 Gbps

## Pre-Installation Checklist

Before proceeding with the demo setup, verify:

- [ ] Kafka is installed and running
- [ ] WarehousePG is installed and accessible
- [ ] FlowServer is installed and configured
- [ ] Go 1.19+ is installed
- [ ] Python 3.8+ is installed
- [ ] All required ports are open
- [ ] You have network access to Kafka and database
- [ ] You have sufficient disk space for data generation

## Verification Script

Run this script to verify all prerequisites:

```bash
#!/bin/bash

echo "Checking prerequisites..."

# Check Kafka
if kafka-broker-api-versions --bootstrap-server localhost:9092 2>/dev/null; then
    echo "✓ Kafka is running"
else
    echo "✗ Kafka is not accessible"
fi

# Check Database
if psql -h localhost -p 5432 -U gpadmin -d postgres -c "SELECT 1" 2>/dev/null; then
    echo "✓ WarehousePG is accessible"
else
    echo "✗ WarehousePG is not accessible"
fi

# Check FlowServer
if flowcli version 2>/dev/null; then
    echo "✓ FlowServer is installed"
else
    echo "✗ FlowServer is not installed"
fi

# Check Go
if go version 2>/dev/null; then
    echo "✓ Go is installed"
else
    echo "✗ Go is not installed"
fi

# Check Python
if python3 --version 2>/dev/null; then
    echo "✓ Python 3 is installed"
else
    echo "✗ Python 3 is not installed"
fi

echo "Prerequisite check complete"
```

## Next Steps

Once all prerequisites are met, proceed to the [main README](../README.md) for installation instructions.
