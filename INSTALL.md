# Installation Guide

Complete step-by-step guide to setting up the FlowServer demo.

## Prerequisites Check

Before starting, ensure all prerequisites are met (see [PREREQUISITES.md](docs/PREREQUISITES.md)):

- ✅ Kafka running on localhost:9092
- ✅ WarehousePG running on localhost:5432
- ✅ FlowServer installed and working
- ✅ Go 1.19+ installed
- ✅ Python 3.8+ installed

## Step 1: Clone Repository

```bash
git clone https://github.com/yourorg/flowserver-demo.git
cd flowserver-demo
```

## Step 2: Database Setup

### Create Database

```bash
psql -h localhost -p 5432 -U gpadmin -d postgres -f sql/01_create_database.sql
```

Expected output:
```
DROP DATABASE
CREATE DATABASE
✓ Database "albaraka" created successfully
```

### Create Tables

```bash
psql -h localhost -p 5432 -U gpadmin -d albaraka -f sql/02_create_tables.sql
```

Expected output:
```
✓ Table "ecommerce_orders" created with indexes
✓ Table "iot_sensor_readings" created with indexes
✓ Permissions granted
```

### Verify Setup

```bash
psql -h localhost -p 5432 -U gpadmin -d albaraka -f sql/03_verify_setup.sql
```

This shows table structures and verifies the database is ready.

## Step 3: Create Kafka Topics

```bash
# Create e-commerce topic
kafka-topics --create \
  --topic ecommerce-orders \
  --bootstrap-server localhost:9092 \
  --partitions 3 \
  --replication-factor 1

# Create IoT topic
kafka-topics --create \
  --topic iot-sensors-csv \
  --bootstrap-server localhost:9092 \
  --partitions 3 \
  --replication-factor 1
```

Verify topics:
```bash
kafka-topics --list --bootstrap-server localhost:9092
```

## Step 4: Build Data Generators

```bash
cd generators

# Download dependencies
go mod download

# Build executables
go build -o order-generator order-generator.go
go build -o iot-generator iot-generator.go

# Verify builds
./order-generator -h
./iot-generator -h

cd ..
```

## Step 5: Install Dashboard Dependencies

```bash
cd dashboards

# Install Python packages
pip install -r requirements.txt --break-system-packages

# Verify installation
python3 -c "import flask, psycopg2; print('✓ Dependencies installed')"

cd ..
```

## Step 6: Submit FlowServer Jobs

### Update Configuration (if needed)

Edit `jobs/ecommerce-orders.yaml` and `jobs/iot-sensors-csv.yaml`:
- Update `brokers` if Kafka is not on localhost:9092
- Update `host`, `port`, `user` if database is not on localhost:5432

### Submit Jobs

```bash
# Submit e-commerce job
flowcli job submit jobs/ecommerce-orders.yaml

# Submit IoT job
flowcli job submit jobs/iot-sensors-csv.yaml
```

### Verify Submission

```bash
flowcli job list
```

Expected output:
```
NAME                 STATUS
ecommerce-orders     submitted
iot-sensors-csv      submitted
```

## Step 7: Start the Demo

```bash
./scripts/start-demo.sh
```

This starts:
- Data generators (e-commerce + IoT)
- FlowServer jobs
- Dashboard APIs
- Web servers

Expected output:
```
==========================================
FlowServer Demo - Starting
==========================================
✓ E-Commerce generator started
✓ IoT generator started
✓ FlowServer jobs started
✓ E-Commerce API started (Port: 5000)
✓ IoT API started (Port: 5001)
✓ E-Commerce web server started (Port: 8666)
✓ IoT web server started (Port: 8668)
==========================================
✓ All services started successfully!
==========================================
```

## Step 8: Verify Everything Works

### Check Service Status

```bash
./scripts/status-demo.sh
```

### Test APIs

```bash
# E-Commerce API
curl http://localhost:5000/api/metrics | jq

# IoT API
curl http://localhost:5001/api/metrics | jq
```

### Check Database Has Data

```bash
psql -h localhost -U gpadmin -d albaraka -c "
  SELECT 'E-Commerce Orders' as table_name, COUNT(*) as count FROM ecommerce_orders
  UNION ALL
  SELECT 'IoT Readings', COUNT(*) FROM iot_sensor_readings;
"
```

After a few seconds, you should see rows appearing.

### View Dashboards

Open in browser:
- E-Commerce: http://localhost:8666/ecommerce-dashboard.html
- IoT: http://localhost:8668/iot.html

## Step 9: Monitor and Verify

### Monitor FlowServer Jobs

```bash
# Check job status
flowcli status ecommerce-orders
flowcli status iot-sensors-csv

# View logs
flowcli logs ecommerce-orders
flowcli logs iot-sensors-csv
```

### Monitor Data Flow

```bash
# Watch database grow
watch -n 1 'psql -h localhost -U gpadmin -d albaraka -t -c "SELECT COUNT(*) FROM ecommerce_orders"'

# Watch Kafka messages
kafka-console-consumer --bootstrap-server localhost:9092 --topic ecommerce-orders --max-messages 5
```

### View Component Logs

```bash
# All logs
tail -f /tmp/flowserver-demo/*.log

# Specific component
tail -f /tmp/flowserver-demo/order-generator.log
```

## Advanced Configuration

### High-Volume Testing

```bash
# Fast data generation
./scripts/stop-demo.sh
./scripts/start-demo.sh --ecom-rate 200 --iot-rate 100
```

### Limited Run

```bash
# Generate exactly 10,000 orders and 5,000 readings
./scripts/start-demo.sh --ecom-total 10000 --iot-total 5000
```

### Custom Database

Edit job YAML files to point to different database:

```yaml
target:
  database:
    host: your-db-host
    port: 5432
    user: your-user
    dbname: your-database
```

Then restart:
```bash
./scripts/stop-demo.sh
flowcli job stop ecommerce-orders
flowcli job stop iot-sensors-csv
flowcli job submit jobs/ecommerce-orders.yaml
flowcli job submit jobs/iot-sensors-csv.yaml
./scripts/start-demo.sh
```

## Stopping the Demo

```bash
./scripts/stop-demo.sh
```

This stops all processes cleanly.

## Cleanup

To completely remove all demo data:

```bash
# Stop demo
./scripts/stop-demo.sh

# Delete Kafka topics
kafka-topics --delete --topic ecommerce-orders --bootstrap-server localhost:9092
kafka-topics --delete --topic iot-sensors-csv --bootstrap-server localhost:9092

# Drop database
psql -h localhost -U gpadmin -d postgres -c "DROP DATABASE albaraka;"

# Remove log files
rm -rf /tmp/flowserver-demo/
```

## Troubleshooting

If you encounter issues, see [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md).

Common first steps:
1. Check all prerequisites are met
2. Verify Kafka and database are running
3. Check logs: `tail -f /tmp/flowserver-demo/*.log`
4. Run status check: `./scripts/status-demo.sh`

## Next Steps

- Explore transformations: [TRANSFORMATIONS.md](docs/TRANSFORMATIONS.md)
- Customize dashboards: [dashboards/README.md](dashboards/README.md)
- Add your own transformations to job YAML files
- Modify generators to produce different data patterns

## Getting Help

- Review documentation in `docs/` directory
- Check FlowServer official documentation
- Open an issue on GitHub
