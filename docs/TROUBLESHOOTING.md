# Troubleshooting Guide

Common issues and solutions for the FlowServer demo.

## Data Generators

### Issue: Generators not connecting to Kafka

**Symptoms**:
```
Failed to create producer: Local: Broker transport failure
```

**Solutions**:
1. Verify Kafka is running:
```bash
kafka-broker-api-versions --bootstrap-server localhost:9092
```

2. Check Kafka logs:
```bash
tail -f $KAFKA_HOME/logs/server.log
```

3. Verify broker address in generator code:
```go
const kafkaBroker = "localhost:9092"  // Update if needed
```

### Issue: No data being generated

**Symptoms**: Generators appear to run but no messages in Kafka

**Solutions**:
1. Check topic exists:
```bash
kafka-topics --list --bootstrap-server localhost:9092
```

2. Create topics if missing:
```bash
kafka-topics --create --topic ecommerce-orders --bootstrap-server localhost:9092 --partitions 3
kafka-topics --create --topic iot-sensors-csv --bootstrap-server localhost:9092 --partitions 3
```

3. Verify messages in Kafka:
```bash
kafka-console-consumer --bootstrap-server localhost:9092 --topic ecommerce-orders --from-beginning --max-messages 5
```

## FlowServer Jobs

### Issue: Job submission fails

**Symptoms**:
```
Error: failed to submit job
```

**Solutions**:
1. Validate YAML syntax:
```bash
yamllint jobs/ecommerce-orders.yaml
```

2. Check FlowServer is running:
```bash
flowcli version
```

3. Verify database connection in YAML:
```yaml
target:
  database:
    host: localhost  # Correct hostname
    port: 5432      # Correct port
    user: gpadmin   # Correct user
```

### Issue: Job running but no data in database

**Symptoms**: Job shows as running but table remains empty

**Solutions**:
1. Check job status and logs:
```bash
flowcli job status ecommerce-orders
flowcli logs ecommerce-orders
```

2. Verify table exists:
```bash
psql -h localhost -U gpadmin -d albaraka -c "\dt"
```

3. Check for errors in logs:
```bash
flowcli logs ecommerce-orders | grep -i error
```

4. Verify data is in Kafka:
```bash
kafka-console-consumer --bootstrap-server localhost:9092 --topic ecommerce-orders --max-messages 1
```

### Issue: High error rate in job

**Symptoms**: Job logs show many rejected records

**Solutions**:
1. Check data format matches schema
2. Verify transformations are valid SQL
3. Increase error_limit in job YAML:
```yaml
target:
  database:
    error_limit: 1000  # Increase from 100
```

## Database

### Issue: Cannot connect to database

**Symptoms**:
```
psql: could not connect to server
```

**Solutions**:
1. Verify WarehousePG is running:
```bash
ps aux | grep postgres
```

2. Check pg_hba.conf allows connections:
```bash
# Add to pg_hba.conf if needed
host    all             all             127.0.0.1/32            trust
```

3. Restart WarehousePG:
```bash
gpstop -a
gpstart -a
```

### Issue: Table does not exist

**Symptoms**:
```
ERROR: relation "ecommerce_orders" does not exist
```

**Solutions**:
1. Run table creation script:
```bash
psql -h localhost -U gpadmin -d albaraka -f sql/02_create_tables.sql
```

2. Verify tables exist:
```bash
psql -h localhost -U gpadmin -d albaraka -c "\dt"
```

## Dashboards

### Issue: API not responding

**Symptoms**: `curl http://localhost:5000/api/metrics` fails

**Solutions**:
1. Check API process is running:
```bash
ps aux | grep "ecommerce-api.py"
```

2. Check API logs:
```bash
tail -f /tmp/flowserver-demo/ecommerce-api.log
```

3. Verify Python dependencies:
```bash
pip list | grep -E "Flask|psycopg2"
```

4. Test database connection from Python:
```bash
python3 -c "import psycopg2; conn = psycopg2.connect('host=localhost port=5432 user=gpadmin dbname=albaraka'); print('OK')"
```

### Issue: Dashboard shows "Loading..." indefinitely

**Symptoms**: Web page loads but shows loading spinner forever

**Solutions**:
1. Open browser console (F12) and check for errors

2. Verify API is accessible:
```bash
curl http://localhost:5000/api/metrics
```

3. Check CORS is enabled in API code:
```python
from flask_cors import CORS
app = Flask(__name__)
CORS(app)  # Must be present
```

4. Verify web server is serving correct files:
```bash
ls -l dashboards/*.html
```

### Issue: Dashboard shows old data

**Symptoms**: Numbers don't update in real-time

**Solutions**:
1. Check refresh interval in HTML:
```javascript
setInterval(fetchMetrics, 2000);  // 2 seconds
```

2. Verify generators are still running:
```bash
./scripts/status-demo.sh
```

3. Clear browser cache (Ctrl+Shift+R)

## Performance Issues

### Issue: Slow data processing

**Symptoms**: Long delay between Kafka and database

**Solutions**:
1. Check batch size in job YAML:
```yaml
source:
  kafka:
    task:
      batch_size:
        interval_ms: 1000  # Reduce for lower latency
```

2. Monitor database performance:
```bash
psql -h localhost -U gpadmin -d albaraka -c "SELECT * FROM pg_stat_activity;"
```

3. Check system resources:
```bash
top
iostat -x 1
```

### Issue: High CPU usage

**Symptoms**: System becomes slow or unresponsive

**Solutions**:
1. Reduce generator rates:
```bash
./scripts/start-demo.sh --ecom-rate 10 --iot-rate 5
```

2. Check for runaway processes:
```bash
top -o %CPU
```

3. Increase system resources if needed

## Log Locations

All logs are stored in `/tmp/flowserver-demo/`:

```bash
# View all logs
tail -f /tmp/flowserver-demo/*.log

# Individual logs
tail -f /tmp/flowserver-demo/order-generator.log
tail -f /tmp/flowserver-demo/iot-generator.log
tail -f /tmp/flowserver-demo/ecommerce-api.log
tail -f /tmp/flowserver-demo/iot-api.log
```

## Getting Help

If you encounter issues not covered here:

1. Check FlowServer documentation
2. Review job logs: `flowcli logs <job-name>`
3. Enable debug logging in APIs:
```python
app.run(host='0.0.0.0', port=5000, debug=True)
```
4. Open an issue on GitHub with:
   - Error messages
   - Log output
   - Steps to reproduce
