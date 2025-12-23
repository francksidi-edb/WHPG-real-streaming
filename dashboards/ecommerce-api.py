#!/usr/bin/env python3
"""
E-Commerce Dashboard API
Provides real-time metrics from the ecommerce_orders table
"""

from flask import Flask, jsonify
from flask_cors import CORS
import psycopg2
import psycopg2.extras
from datetime import datetime, timedelta

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
    """Get key e-commerce metrics"""
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    
    # Total revenue and orders
    cur.execute("""
        SELECT 
            COUNT(*) as total_orders,
            COALESCE(SUM(total_price), 0) as total_revenue,
            COALESCE(AVG(total_price), 0) as avg_order_value
        FROM ecommerce_orders
    """)
    totals = cur.fetchone()
    
    # Recent rate (last minute)
    cur.execute("""
        SELECT COUNT(*) as recent_orders
        FROM ecommerce_orders
        WHERE timestamp > NOW() - INTERVAL '1 minute'
    """)
    recent = cur.fetchone()
    
    # Revenue by bucket
    cur.execute("""
        SELECT 
            revenue_bucket,
            COUNT(*) as order_count,
            SUM(total_price) as revenue
        FROM ecommerce_orders
        GROUP BY revenue_bucket
        ORDER BY 
            CASE revenue_bucket
                WHEN 'low' THEN 1
                WHEN 'medium' THEN 2
                WHEN 'high' THEN 3
                WHEN 'premium' THEN 4
            END
    """)
    buckets = cur.fetchall()
    
    # Top categories
    cur.execute("""
        SELECT 
            category,
            COUNT(*) as order_count,
            SUM(total_price) as revenue
        FROM ecommerce_orders
        GROUP BY category
        ORDER BY revenue DESC
        LIMIT 5
    """)
    categories = cur.fetchall()
    
    # Geographic distribution
    cur.execute("""
        SELECT 
            country,
            COUNT(*) as order_count,
            SUM(total_price) as revenue
        FROM ecommerce_orders
        GROUP BY country
        ORDER BY revenue DESC
        LIMIT 10
    """)
    countries = cur.fetchall()
    
    cur.close()
    conn.close()
    
    return jsonify({
        'timestamp': datetime.now().isoformat(),
        'totals': {
            'total_orders': int(totals['total_orders']),
            'total_revenue': float(totals['total_revenue']),
            'avg_order_value': float(totals['avg_order_value']),
            'orders_per_minute': int(recent['recent_orders'])
        },
        'revenue_buckets': [dict(b) for b in buckets],
        'top_categories': [dict(c) for c in categories],
        'countries': [dict(c) for c in countries]
    })

@app.route('/api/recent', methods=['GET'])
def get_recent_orders():
    """Get recent orders"""
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    
    cur.execute("""
        SELECT 
            order_id,
            timestamp,
            customer_name,
            product_name,
            category,
            total_price,
            revenue_bucket,
            country
        FROM ecommerce_orders
        ORDER BY timestamp DESC
        LIMIT 20
    """)
    orders = cur.fetchall()
    
    cur.close()
    conn.close()
    
    return jsonify([dict(o) for o in orders])

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
    app.run(host='0.0.0.0', port=5000, debug=False)
