# Dashboards

Real-time web dashboards for visualizing FlowServer streaming data.

## Components

### APIs (Python Flask)

- `ecommerce-api.py` - E-commerce metrics API (port 5000)
- `iot-api.py` - IoT sensor metrics API (port 5001)

### Web Dashboards (HTML/JavaScript)

- `ecommerce-dashboard.html` - E-commerce analytics dashboard
- `iot.html` - IoT sensor monitoring dashboard

## Installation

```bash
# Install Python dependencies
pip install -r requirements.txt --break-system-packages

# Or install individually
pip install flask flask-cors psycopg2-binary --break-system-packages
```

## Running

### Start APIs

```bash
# E-Commerce API
python3 ecommerce-api.py &

# IoT API
python3 iot-api.py &
```

### Start Web Servers

```bash
# E-Commerce dashboard
python3 -m http.server 8666 --bind 0.0.0.0 &

# IoT dashboard
python3 -m http.server 8668 --bind 0.0.0.0 &
```

### Access Dashboards

- E-Commerce: http://localhost:8666/ecommerce-dashboard.html
- IoT: http://localhost:8668/iot.html

## API Endpoints

### E-Commerce API (port 5000)

- `GET /api/metrics` - Key metrics (revenue, orders, categories)
- `GET /api/recent` - Recent orders
- `GET /api/health` - Health check

### IoT API (port 5001)

- `GET /api/metrics` - Key metrics (readings, sensors, alerts)
- `GET /api/sensors` - Per-sensor statistics
- `GET /api/recent` - Recent sensor readings
- `GET /api/health` - Health check

## Configuration

### Database Connection

Edit API files to change database settings:

```python
DB_CONFIG = {
    'host': 'localhost',
    'port': 5432,
    'user': 'gpadmin',
    'password': '',
    'database': 'albaraka'
}
```

### API Ports

Change ports in the `app.run()` call:

```python
app.run(host='0.0.0.0', port=5000)
```

### Dashboard Refresh Rate

Edit HTML files to change refresh interval:

```javascript
setInterval(fetchMetrics, 2000); // 2 seconds
```

## Troubleshooting

### API not responding

```bash
# Check process is running
ps aux | grep "ecommerce-api.py"

# Check logs
tail -f /tmp/flowserver-demo/ecommerce-api.log

# Test endpoint
curl http://localhost:5000/api/health
```

### Dashboard shows loading

1. Open browser console (F12) to check for errors
2. Verify API is accessible: `curl http://localhost:5000/api/metrics`
3. Check CORS is enabled in API code

### No data displayed

1. Verify database has data: `psql -h localhost -U gpadmin -d albaraka -c "SELECT COUNT(*) FROM ecommerce_orders;"`
2. Check FlowServer jobs are running: `flowcli status ecommerce-orders`
3. Verify generators are sending data

## Development

### Adding New Metrics

1. Add SQL query to API endpoint
2. Update JSON response format
3. Add visualization to HTML dashboard
4. Test with sample data

### Customizing UI

Dashboards use:
- Chart.js for visualizations
- Vanilla JavaScript (no frameworks)
- CSS Grid for layout
- Al Baraka color scheme (green #00704A, gold #D4AF37)

## Dependencies

- Flask 2.3.0
- flask-cors 4.0.0
- psycopg2-binary 2.9.9
