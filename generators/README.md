# Data Generators

Go-based data generators for the FlowServer demo.

## Building

```bash
go mod download
go build -o order-generator order-generator.go
go build -o iot-generator iot-generator.go
```

## Usage

### E-Commerce Order Generator

```bash
./order-generator [OPTIONS]

Options:
  -rate N          Orders per second (default: 10)
  -max-messages N  Maximum orders to generate (default: 0=unlimited)

Examples:
  ./order-generator                    # 10 orders/sec, unlimited
  ./order-generator -rate 50           # 50 orders/sec
  ./order-generator -max-messages 1000 # Generate exactly 1000 orders
```

### IoT Sensor Generator

```bash
./iot-generator [OPTIONS]

Options:
  -rate N          Readings per second (default: 10)
  -max-messages N  Maximum readings to generate (default: 0=unlimited)

Examples:
  ./iot-generator                      # 10 readings/sec, unlimited
  ./iot-generator -rate 20             # 20 readings/sec
  ./iot-generator -max-messages 5000   # Generate exactly 5000 readings
```

## Data Format

### E-Commerce Orders (JSON)
```json
{
  "order_id": "ORD-000001",
  "timestamp": "2024-12-22 10:30:45",
  "customer_id": "CUST-00123",
  "customer_name": "Ahmed Al-Saud",
  "customer_email": "ahmed.al-saud@example.com",
  "product_id": "PROD-0042",
  "product_name": "Product 42",
  "category": "Electronics",
  "quantity": 2,
  "unit_price": 499.90,
  "total_price": 999.80,
  "payment_method": "Credit Card",
  "country": "Saudi Arabia",
  "city": "Riyadh"
}
```

### IoT Sensor Readings (CSV)
```csv
timestamp,sensor_id,location,temperature,humidity,pressure,battery_level,status
2024-12-22 10:30:45,SENS-001,Warehouse-Floor-2,28.50,65.20,1013.25,85.30,normal
```

## Dependencies

- Go 1.19+
- confluent-kafka-go v1.9.2
- Apache Kafka running on localhost:9092
