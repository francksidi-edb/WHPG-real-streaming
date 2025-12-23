#!/usr/bin/env python3
"""
IoT Sensor Dashboard API
Provides real-time metrics from the iot_sensor_readings table
"""

from flask import Flask, jsonify
from flask_cors import CORS
import psycopg2
import psycopg2.extras
from datetime import datetime

app = Flask(__name__)
CORS(app)

# Database configuration
DB_CONFIG = {
    'host': 'localhost',
    'port': 5432,
    'user': 'gpadmin',
    'password': '',
    'database': 'albaraka'
}

def get_db_connection():
    return psycopg2.connect(**DB_CONFIG)

@app.route('/api/metrics', methods=['GET'])
def get_metrics():
    """Get key IoT metrics"""
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    
    # Total readings and sensors
    cur.execute("""
        SELECT 
            COUNT(*) as total_readings,
            COUNT(DISTINCT sensor_id) as active_sensors
        FROM iot_sensor_readings
    """)
    totals = cur.fetchone()
    
    # Recent rate (last minute)
    cur.execute("""
        SELECT COUNT(*) as recent_readings
        FROM iot_sensor_readings
        WHERE timestamp > NOW() - INTERVAL '1 minute'
    """)
    recent = cur.fetchone()
    
    # Alert level distribution
    cur.execute("""
        SELECT 
            alert_level,
            COUNT(*) as reading_count
        FROM iot_sensor_readings
        GROUP BY alert_level
        ORDER BY alert_level
    """)
    alerts = cur.fetchall()
    
    # Building distribution
    cur.execute("""
        SELECT 
            building,
            COUNT(*) as reading_count,
            AVG(temperature) as avg_temp,
            AVG(humidity) as avg_humidity
        FROM iot_sensor_readings
        WHERE building IS NOT NULL
        GROUP BY building
        ORDER BY building
    """)
    buildings = cur.fetchall()
    
    # Comfort index distribution
    cur.execute("""
        SELECT 
            comfort_index,
            COUNT(*) as count
        FROM iot_sensor_readings
        WHERE comfort_index IS NOT NULL
        GROUP BY comfort_index
    """)
    comfort = cur.fetchall()
    
    cur.close()
    conn.close()
    
    return jsonify({
        'timestamp': datetime.now().isoformat(),
        'totals': {
            'total_readings': int(totals['total_readings']),
            'active_sensors': int(totals['active_sensors']),
            'readings_per_minute': int(recent['recent_readings'])
        },
        'alerts': [dict(a) for a in alerts],
        'buildings': [dict(b) for b in buildings],
        'comfort': [dict(c) for c in comfort]
    })

@app.route('/api/sensors', methods=['GET'])
def get_sensors():
    """Get per-sensor metrics"""
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    
    cur.execute("""
        SELECT 
            sensor_id,
            building,
            floor,
            COUNT(*) as reading_count,
            AVG(temperature) as avg_temp,
            AVG(temperature_f) as avg_temp_f,
            AVG(humidity) as avg_humidity,
            AVG(battery_level) as avg_battery,
            MAX(timestamp) as last_reading
        FROM iot_sensor_readings
        WHERE building IS NOT NULL
        GROUP BY sensor_id, building, floor
        ORDER BY sensor_id
    """)
    sensors = cur.fetchall()
    
    cur.close()
    conn.close()
    
    return jsonify([dict(s) for s in sensors])

@app.route('/api/recent', methods=['GET'])
def get_recent_readings():
    """Get recent sensor readings"""
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    
    cur.execute("""
        SELECT 
            timestamp,
            sensor_id,
            building,
            floor,
            temperature,
            temperature_f,
            humidity,
            comfort_index,
            alert_level,
            status
        FROM iot_sensor_readings
        ORDER BY timestamp DESC
        LIMIT 50
    """)
    readings = cur.fetchall()
    
    cur.close()
    conn.close()
    
    return jsonify([dict(r) for r in readings])

@app.route('/api/health', methods=['GET'])
def health():
    """Health check endpoint"""
    try:
        conn = get_db_connection()
        conn.close()
        return jsonify({'status': 'healthy', 'timestamp': datetime.now().isoformat()})
    except Exception as e:
        return jsonify({'status': 'unhealthy', 'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001, debug=False)
