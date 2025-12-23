# FlowServer Real-Time Streaming Demo

A complete demonstration of **FlowServer** real-time data streaming capabilities, featuring dual-stream processing (E-Commerce + IoT) with live dashboards and advanced transformations.


## What This Demo Shows

- **Multi-Format Streaming**: Simultaneous processing of JSON and CSV data streams
- **Real-Time Transformations**: 9+ data enrichments applied in-flight
- **Zero-Error Processing**: 100% data accuracy at high throughput
- **Live Dashboards**: Real-time visualization with 2-second refresh cycles
- **Production Performance**: 70+ messages/second with sub-second latency

## Demo Components

### E-Commerce Stream
- **Source**: Kafka topic `ecommerce-orders` (JSON format)
- **Processing Rate**: 50 orders/second
- **Transformations**: Revenue bucket classification, bulk order detection
- **Dashboard**: Real-time revenue tracking, customer segmentation, geographic distribution

### IoT Sensor Stream
- **Source**: Kafka topic `iot-sensors-csv` (CSV format)
- **Processing Rate**: 20 readings/second
- **Transformations**: Building/floor extraction, temperature conversion (C→F), comfort index, alert levels, data quality validation
- **Dashboard**: Multi-building sensor monitoring, alert tracking, environmental metrics

## Quick Start

### Prerequisites

- **Apache Kafka** installed and running
- **WarehousePG** (Greenplum fork) installed
- **FlowServer** installed and configured
- **Python 3.8+** with pip
- **Go 1.19+** (for data generators)

### Installation Steps

1. **Clone the repository**
```bash
git clone https://github.com/francksidi-edb/WHPG-real-streaming.git
cd flowserver-demo
```

2. **Create database and tables**
```bash
psql -h localhost -p 5432 -U gpadmin -d postgres -f sql/01_create_database.sql
psql -h localhost -p 5432 -U gpadmin -d albaraka -f sql/02_create_tables.sql
```

3. **Create Kafka topics**
```bash
kafka-topics --create --topic ecommerce-orders --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1
kafka-topics --create --topic iot-sensors-csv --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1
```

4. **Build data generators**
```bash
cd generators
go build -o order-generator order-generator.go
go build -o iot-generator iot-generator.go
cd ..
```

5. **Install dashboard dependencies**
```bash
cd dashboards
pip install flask psycopg2-binary --break-system-packages
cd ..
```

6. **Submit FlowServer jobs**
```bash
flowcli job submit jobs/ecommerce-orders.yaml
flowcli job submit jobs/iot-sensors-csv.yaml
```

7. **Start the demo**
```bash
./scripts/start-demo.sh
```

8. **Access dashboards**
- E-Commerce: http://localhost:8666/ecommerce-dashboard.html
- IoT Sensors: http://localhost:8668/iot.html

## Project Structure

```
flowserver-demo/
├── README.md                 # This file
├── sql/                      # Database setup scripts
│   ├── 01_create_database.sql
│   ├── 02_create_tables.sql
│   └── 03_verify_setup.sql
├── jobs/                     # FlowServer job configurations
│   ├── ecommerce-orders.yaml
│   └── iot-sensors-csv.yaml
├── generators/               # Data generators (Go)
│   ├── order-generator.go
│   └── iot-generator.go
├── dashboards/               # Web dashboards
│   ├── ecommerce-api.py
│   ├── ecommerce-dashboard.html
│   ├── iot-api.py
│   └── iot.html
├── scripts/                  # Control scripts
│   ├── start-demo.sh
│   ├── stop-demo.sh
│   └── status-demo.sh
└── docs/                     # Documentation
    ├── PREREQUISITES.md
    ├── TROUBLESHOOTING.md
    └── TRANSFORMATIONS.md
```

## Demo Control Scripts

### Start Full Demo
```bash
./scripts/start-demo.sh [OPTIONS]

Options:
  --ecom-rate N      E-commerce orders per second (default: 50)
  --iot-rate N       IoT readings per second (default: 20)
  --ecom-total N     Total e-commerce orders (0=unlimited, default: 0)
  --iot-total N      Total IoT readings (0=unlimited, default: 0)

Examples:
  ./scripts/start-demo.sh                          # Start with defaults
  ./scripts/start-demo.sh --ecom-rate 100          # Faster e-commerce stream
  ./scripts/start-demo.sh --ecom-total 10000       # Generate 10K orders then stop
```

### Stop Demo
```bash
./scripts/stop-demo.sh
```

### Check Status
```bash
./scripts/status-demo.sh
```

## Configuration

### Kafka Brokers
Update broker addresses in:
- `jobs/ecommerce-orders.yaml` (line 5)
- `jobs/iot-sensors-csv.yaml` (line 5)
- `generators/order-generator.go` (line 15)
- `generators/iot-generator.go` (line 15)

### Database Connection
Update database settings in:
- `jobs/ecommerce-orders.yaml` (lines 18-22)
- `jobs/iot-sensors-csv.yaml` (lines 18-22)
- `dashboards/ecommerce-api.py` (lines 8-12)
- `dashboards/iot-api.py` (lines 8-12)

## Key Transformations

### E-Commerce: Revenue Bucket
```sql
CASE 
  WHEN total_price < 100 THEN 'low'
  WHEN total_price < 500 THEN 'medium'
  WHEN total_price < 1000 THEN 'high'
  ELSE 'premium'
END
```

### IoT: Comfort Index
```sql
CASE
  WHEN temperature BETWEEN 20 AND 24 
   AND humidity BETWEEN 40 AND 60 THEN 'comfortable'
  WHEN temperature BETWEEN 18 AND 26 
   AND humidity BETWEEN 35 AND 65 THEN 'acceptable'
  ELSE 'uncomfortable'
END
```
---
See [TRANSFORMATIONS.md](docs/TRANSFORMATIONS.md) for complete details.

## QUICK DASHBOARD ACCESS

After running `./scripts/start-demo.sh`, open these URLs in your browser:

### Local Access (on the server):
```
http://localhost:8666/ecommerce-dashboard.html
http://localhost:8668/iot.html
```

### Remote Access (from your laptop):
Replace localhost with server IP/hostname:
```
http://YOUR_SERVER_IP:8666/ecommerce-dashboard.html
http://YOUR_SERVER_IP:8668/iot.html
```

### Find Your Server IP:
```bash
hostname -I | awk '{print $1}'
```

### Verify Everything Works:
```bash
./scripts/status-demo.sh
```

### If Dashboard Shows "Loading...":
1. Open browser console (F12) - check for errors
2. Test API: `curl http://localhost:5000/api/health`
3. Check data: `psql -h localhost -U gpadmin -d albaraka -c "SELECT COUNT(*) FROM ecommerce_orders;"`



## Performance Metrics

- **Throughput**: 70+ messages/second (dual streams)
- **Latency**: < 1 second end-to-end (Kafka → Database)
- **Error Rate**: 0% (zero rejections)
- **Uptime**: Continuous operation (tested 24+ hours)

## Troubleshooting

### Generators not connecting to Kafka
```bash
# Check Kafka is running
kafka-broker-api-versions --bootstrap-server localhost:9092

# Verify topics exist
kafka-topics --list --bootstrap-server localhost:9092
```

### FlowServer jobs failing
```bash
# Check job status
flowcli status ecommerce-orders
flowcli status iot-sensors-csv

# View job logs
flowcli logs ecommerce-orders
flowcli logs iot-sensors-csv
```

### Dashboards not loading data
```bash
# Test database connection
psql -h localhost -p 5432 -U gpadmin -d albaraka -c "SELECT COUNT(*) FROM ecommerce_orders;"

# Check API is running
curl http://localhost:5000/api/metrics
curl http://localhost:5001/api/metrics
```

See [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for more help.

## 📝 License

MIT License - See LICENSE file for details

## 🤝 Contributing

Contributions welcome! Please open an issue or submit a pull request.

## 📧 Contact

For questions or support, please open an issue on GitHub.

---
**Built with**: FlowServer • WarehousePG • Kafka • Python • Go
