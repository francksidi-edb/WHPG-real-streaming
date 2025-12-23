package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"math/rand"
	"time"

	"github.com/confluentinc/confluent-kafka-go/kafka"
)

const (
	kafkaBroker = "localhost:9092"
	kafkaTopic  = "ecommerce-orders"
)

var (
	categories = []string{"Electronics", "Clothing", "Books", "Home & Garden", "Sports", "Toys"}
	countries  = []string{"Saudi Arabia", "UAE", "Egypt", "Jordan", "Kuwait", "Bahrain", "Oman", "Qatar"}
	cities     = []string{"Riyadh", "Dubai", "Cairo", "Amman", "Kuwait City", "Manama", "Muscat", "Doha"}
	paymentMethods = []string{"Credit Card", "Debit Card", "Cash", "PayPal", "Apple Pay"}
	
	firstNames = []string{"Ahmed", "Fatima", "Mohammed", "Aisha", "Ali", "Sara", "Omar", "Layla"}
	lastNames  = []string{"Al-Saud", "Hassan", "Ibrahim", "Abdullah", "Al-Rashid", "Khalil"}
)

type Order struct {
	OrderID        string  `json:"order_id"`
	Timestamp      string  `json:"timestamp"`
	CustomerID     string  `json:"customer_id"`
	CustomerName   string  `json:"customer_name"`
	CustomerEmail  string  `json:"customer_email"`
	ProductID      string  `json:"product_id"`
	ProductName    string  `json:"product_name"`
	Category       string  `json:"category"`
	Quantity       int     `json:"quantity"`
	UnitPrice      float64 `json:"unit_price"`
	TotalPrice     float64 `json:"total_price"`
	PaymentMethod  string  `json:"payment_method"`
	Country        string  `json:"country"`
	City           string  `json:"city"`
}

func generateOrder(orderNum int) Order {
	quantity := rand.Intn(5) + 1
	unitPrice := float64(rand.Intn(9900)+100) / 10.0
	
	firstName := firstNames[rand.Intn(len(firstNames))]
	lastName := lastNames[rand.Intn(len(lastNames))]
	
	return Order{
		OrderID:       fmt.Sprintf("ORD-%06d", orderNum),
		Timestamp:     time.Now().Format("2006-01-02 15:04:05"),
		CustomerID:    fmt.Sprintf("CUST-%05d", rand.Intn(1000)),
		CustomerName:  fmt.Sprintf("%s %s", firstName, lastName),
		CustomerEmail: fmt.Sprintf("%s.%s@example.com", firstName, lastName),
		ProductID:     fmt.Sprintf("PROD-%04d", rand.Intn(500)),
		ProductName:   fmt.Sprintf("Product %d", rand.Intn(100)),
		Category:      categories[rand.Intn(len(categories))],
		Quantity:      quantity,
		UnitPrice:     unitPrice,
		TotalPrice:    float64(quantity) * unitPrice,
		PaymentMethod: paymentMethods[rand.Intn(len(paymentMethods))],
		Country:       countries[rand.Intn(len(countries))],
		City:          cities[rand.Intn(len(cities))],
	}
}

func main() {
	rate := flag.Int("rate", 10, "Orders per second")
	maxMessages := flag.Int("max-messages", 0, "Maximum messages to send (0=unlimited)")
	flag.Parse()

	log.Printf("Starting order generator: %d orders/sec, max=%d", *rate, *maxMessages)

	// Create Kafka producer
	p, err := kafka.NewProducer(&kafka.ConfigMap{
		"bootstrap.servers": kafkaBroker,
	})
	if err != nil {
		log.Fatalf("Failed to create producer: %s", err)
	}
	defer p.Close()

	// Delivery report handler
	go func() {
		for e := range p.Events() {
			switch ev := e.(type) {
			case *kafka.Message:
				if ev.TopicPartition.Error != nil {
					log.Printf("Delivery failed: %v", ev.TopicPartition.Error)
				}
			}
		}
	}()

	ticker := time.NewTicker(time.Second / time.Duration(*rate))
	defer ticker.Stop()

	count := 0
	for range ticker.C {
		if *maxMessages > 0 && count >= *maxMessages {
			log.Printf("Reached maximum messages (%d), stopping", *maxMessages)
			break
		}

		order := generateOrder(count + 1)
		jsonData, _ := json.Marshal(order)

		err := p.Produce(&kafka.Message{
			TopicPartition: kafka.TopicPartition{Topic: &kafkaTopic, Partition: kafka.PartitionAny},
			Value:          jsonData,
		}, nil)

		if err != nil {
			log.Printf("Failed to produce message: %s", err)
		} else {
			count++
			if count%100 == 0 {
				log.Printf("Sent %d orders", count)
			}
		}
	}

	// Flush any pending messages
	p.Flush(15 * 1000)
	log.Printf("Generator stopped. Total orders sent: %d", count)
}
