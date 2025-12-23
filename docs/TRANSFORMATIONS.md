# Data Transformations

Detailed documentation of all real-time transformations applied by FlowServer.

## E-Commerce Transformations

### 1. Revenue Bucket Classification

**Purpose**: Categorize orders into revenue tiers for customer segmentation

**Logic**:
```sql
CASE 
  WHEN (order_data->>'total_price')::decimal < 100 THEN 'low'
  WHEN (order_data->>'total_price')::decimal < 500 THEN 'medium'
  WHEN (order_data->>'total_price')::decimal < 1000 THEN 'high'
  ELSE 'premium'
END
```

**Input**: `total_price` (decimal)

**Output**: `revenue_bucket` (varchar)

**Example**:
| Total Price | Revenue Bucket |
|-------------|----------------|
| $75.00      | low            |
| $299.99     | medium         |
| $749.50     | high           |
| $2,499.00   | premium        |

**Business Value**:
- Instant customer segmentation
- Enables targeted marketing
- Real-time revenue analytics
- No post-processing required

### 2. Bulk Order Detection

**Purpose**: Flag high-quantity orders for special handling

**Logic**:
```sql
(order_data->>'quantity')::integer > 2
```

**Input**: `quantity` (integer)

**Output**: `is_bulk_order` (boolean)

**Example**:
| Quantity | Is Bulk Order |
|----------|---------------|
| 1        | false         |
| 2        | false         |
| 3        | true          |
| 10       | true          |

**Business Value**:
- Identify wholesale customers
- Trigger inventory alerts
- Enable volume pricing logic

### 3. Processing Timestamp

**Purpose**: Track when data was ingested

**Logic**:
```sql
NOW()
```

**Input**: (none)

**Output**: `processing_time` (timestamp)

**Business Value**:
- Calculate end-to-end latency
- Audit trail for data processing
- Monitor pipeline performance

## IoT Sensor Transformations

### 1. Alert Level Calculation

**Purpose**: Convert status strings to numeric alert levels

**Logic**:
```sql
CASE 
  WHEN col_status = 'normal' THEN 0
  WHEN col_status IN ('high_temp', 'low_temp', 'high_humidity') THEN 1
  WHEN col_status = 'low_battery' THEN 2
  ELSE 3
END
```

**Input**: `status` (varchar)

**Output**: `alert_level` (integer, 0-3)

**Example**:
| Status         | Alert Level | Severity  |
|----------------|-------------|-----------|
| normal         | 0           | None      |
| high_temp      | 1           | Warning   |
| low_battery    | 2           | Attention |
| critical_error | 3           | Critical  |

**Business Value**:
- Standardized alerting system
- Easy filtering by severity
- Integration with monitoring tools

### 2. Building Name Extraction

**Purpose**: Parse building name from location string

**Logic**:
```sql
SPLIT_PART(col_location, '-', 1)
```

**Input**: `location` (varchar, format: "Building-Floor-Number")

**Output**: `building` (varchar)

**Example**:
| Location           | Building  |
|--------------------|-----------|
| Warehouse-Floor-2  | Warehouse |
| Parking-Floor-1    | Parking   |
| Rooftop-Floor-5    | Rooftop   |

**Business Value**:
- Group sensors by building
- Building-level analytics
- Facility management integration

### 3. Floor Number Extraction

**Purpose**: Parse floor number from location string

**Logic**:
```sql
CASE 
  WHEN col_location LIKE '%Floor-%' 
  THEN CAST(SPLIT_PART(col_location, '-', 3) AS INTEGER)
  ELSE NULL
END
```

**Input**: `location` (varchar)

**Output**: `floor` (integer)

**Example**:
| Location           | Floor |
|--------------------|-------|
| Warehouse-Floor-2  | 2     |
| Parking-Floor-1    | 1     |
| Rooftop-Floor-5    | 5     |

**Business Value**:
- Floor-by-floor monitoring
- Vertical space management
- Emergency response planning

### 4. Temperature Conversion (C → F)

**Purpose**: Convert Celsius to Fahrenheit for US audiences

**Logic**:
```sql
(col_temperature::decimal * 9.0 / 5.0) + 32.0
```

**Input**: `temperature` (decimal, Celsius)

**Output**: `temperature_f` (decimal, Fahrenheit)

**Example**:
| Temperature (°C) | Temperature (°F) |
|------------------|------------------|
| 0                | 32.0             |
| 20               | 68.0             |
| 25               | 77.0             |
| 30               | 86.0             |

**Business Value**:
- International compatibility
- No client-side conversion needed
- Historical data in both units

### 5. Comfort Index

**Purpose**: Classify environmental comfort based on temperature and humidity

**Logic**:
```sql
CASE
  WHEN col_temperature::decimal BETWEEN 20 AND 24 
   AND col_humidity::decimal BETWEEN 40 AND 60 THEN 'comfortable'
  WHEN col_temperature::decimal BETWEEN 18 AND 26 
   AND col_humidity::decimal BETWEEN 35 AND 65 THEN 'acceptable'
  ELSE 'uncomfortable'
END
```

**Input**: `temperature` (decimal), `humidity` (decimal)

**Output**: `comfort_index` (varchar)

**Example**:
| Temperature | Humidity | Comfort Index |
|-------------|----------|---------------|
| 22°C        | 50%      | comfortable   |
| 25°C        | 62%      | acceptable    |
| 30°C        | 75%      | uncomfortable |
| 16°C        | 40%      | uncomfortable |

**Business Value**:
- HVAC optimization
- Employee comfort monitoring
- Energy efficiency insights

### 6. Battery Status Classification

**Purpose**: Categorize battery levels for maintenance scheduling

**Logic**:
```sql
CASE
  WHEN col_battery_level::decimal >= 80 THEN 'good'
  WHEN col_battery_level::decimal >= 40 THEN 'medium'
  WHEN col_battery_level::decimal >= 20 THEN 'low'
  ELSE 'critical'
END
```

**Input**: `battery_level` (decimal, percentage)

**Output**: `battery_status` (varchar)

**Example**:
| Battery Level | Battery Status |
|---------------|----------------|
| 95%           | good           |
| 65%           | medium         |
| 25%           | low            |
| 10%           | critical       |

**Business Value**:
- Proactive maintenance
- Prevent sensor downtime
- Battery replacement planning

### 7. Data Quality Validation

**Purpose**: Flag suspicious or out-of-range readings

**Logic**:
```sql
CASE
  WHEN col_temperature::decimal BETWEEN -40 AND 50 
   AND col_humidity::decimal BETWEEN 0 AND 100
   AND col_pressure::decimal BETWEEN 900 AND 1100
  THEN 'valid'
  ELSE 'suspicious'
END
```

**Input**: `temperature`, `humidity`, `pressure`

**Output**: `data_quality` (varchar)

**Validation Ranges**:
- Temperature: -40°C to 50°C
- Humidity: 0% to 100%
- Pressure: 900 to 1100 hPa

**Business Value**:
- Early detection of sensor malfunctions
- Data quality metrics
- Automated anomaly detection

### 8. Processing Timestamp

**Purpose**: Track when data was ingested

**Logic**:
```sql
NOW()
```

**Input**: (none)

**Output**: `processed_at` (timestamp)

**Business Value**:
- Calculate processing latency
- Audit trail
- Performance monitoring

## Transformation Performance

All transformations are applied **in-flight** during data streaming:

| Metric | Value |
|--------|-------|
| Processing Time | < 100ms per record |
| CPU Overhead | < 5% |
| Memory Usage | Minimal (stateless) |
| Accuracy | 100% (no approximation) |

## Why Transform at Ingestion?

### Advantages

1. **Lower Latency**: Data is immediately usable
2. **Reduced Storage**: Only store enriched data once
3. **Consistent Logic**: Transformations applied uniformly
4. **Better Performance**: No post-processing queries needed
5. **Simplified Queries**: Dashboards query pre-computed fields

### Compared to Post-Processing

| Approach | Latency | Storage | Query Speed |
|----------|---------|---------|-------------|
| Ingestion Transform | < 1s | 1x | Fast |
| Post-Processing | Minutes | 2x | Slow |
| Client-Side | < 1s | 1x | Very Slow |

## Adding Custom Transformations

To add new transformations, edit the job YAML files:

```yaml
mapping:
  # Add new computed field
  my_custom_field: |
    CASE 
      WHEN condition THEN 'value1'
      ELSE 'value2'
    END
```

Supported SQL functions:
- String: `SPLIT_PART`, `SUBSTRING`, `CONCAT`, `UPPER`, `LOWER`
- Math: `ROUND`, `CEIL`, `FLOOR`, `ABS`, `POW`
- Date: `NOW`, `EXTRACT`, `DATE_TRUNC`
- Conditional: `CASE`, `COALESCE`, `NULLIF`
- Comparison: `BETWEEN`, `IN`, `LIKE`

## Best Practices

1. **Keep Transformations Stateless**: No dependencies on previous records
2. **Use CASE for Categorization**: Cleaner than multiple conditions
3. **Validate Input Ranges**: Prevent garbage in, garbage out
4. **Document Logic**: Comments in YAML help maintenance
5. **Test with Sample Data**: Verify before production deployment
