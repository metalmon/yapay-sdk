package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"plugin"
	"strings"
	"time"

	"github.com/metalmon/yapay-sdk"
	"github.com/metalmon/yapay-sdk/testing"
)

// loadPlugin loads a plugin using the same logic as the main application
func loadPlugin(name, pluginsDir string) (*plugin.Plugin, error) {
	// Try subdirectory first, then root for legacy support
	pluginPath := filepath.Join(pluginsDir, name, name+".so")
	if _, err := os.Stat(pluginPath); os.IsNotExist(err) {
		pluginPath = filepath.Join(pluginsDir, name+".so")
		if _, err := os.Stat(pluginPath); os.IsNotExist(err) {
			return nil, fmt.Errorf("plugin file not found: %s", name)
		}
	}

	fmt.Printf("Loading plugin from: %s\n", pluginPath)
	p, err := plugin.Open(pluginPath)
	if err != nil {
		return nil, fmt.Errorf("failed to open plugin %s: %w", name, err)
	}

	return p, nil
}

func main() {
	var (
		pluginName = flag.String("plugin", "", "Plugin name (e.g., swschool)")
		configPath = flag.String("config", "", "Path to plugin config.yaml")
		testMode   = flag.String("test", "", "Test mode: validate, simulate, benchmark")
		verbose    = flag.Bool("verbose", false, "Verbose output")
		pluginsDir = flag.String("plugins-dir", "plugins", "Plugins directory")
	)
	flag.Parse()

	if *pluginName == "" {
		fmt.Println("Usage: plugin-debug -plugin <plugin-name> [-config <path/to/config.yaml>] [-test <mode>] [-plugins-dir <dir>]")
		fmt.Println("Test modes: validate, simulate, benchmark")
		fmt.Println("Example: plugin-debug -plugin swschool -test validate")
		os.Exit(1)
	}

	// Load plugin using the same logic as main application
	fmt.Printf("Loading plugin: %s\n", *pluginName)
	p, err := loadPlugin(*pluginName, *pluginsDir)
	if err != nil {
		log.Fatalf("Failed to load plugin: %v", err)
	}

	// Look for NewHandler function
	newHandlerSym, err := p.Lookup("NewHandler")
	if err != nil {
		log.Fatalf("Plugin does not export NewHandler function: %v", err)
	}

	newHandler, ok := newHandlerSym.(func(*yapay.Merchant) yapay.ClientHandler)
	if !ok {
		log.Fatalf("NewHandler has wrong signature: expected func(*yapay.Merchant) yapay.ClientHandler")
	}

	// Load config if provided
	var merchant *yapay.Merchant
	if *configPath != "" {
		fmt.Printf("Loading config: %s\n", *configPath)
		merchant, err = loadConfig(*configPath)
		if err != nil {
			log.Fatalf("Failed to load config: %v", err)
		}
	} else {
		// Use test data
		fmt.Println("Using test merchant configuration")
		testData := testing.NewTestData()
		merchant = testData.CreateTestMerchant()
	}

	// Create handler
	fmt.Println("Creating handler...")
	handler := newHandler(merchant)

	// Validate handler
	fmt.Println("Validating handler...")
	if err := validateHandler(handler); err != nil {
		log.Fatalf("Handler validation failed: %v", err)
	}
	fmt.Println("✅ Handler validation passed")

	// Run tests based on mode
	switch *testMode {
	case "validate":
		runValidationTests(handler, *verbose)
	case "simulate":
		runSimulationTests(handler, *verbose)
	case "benchmark":
		runBenchmarkTests(handler, *verbose)
	default:
		fmt.Println("No test mode specified. Use -test validate|simulate|benchmark")
	}
}

func loadConfig(configPath string) (*yapay.Merchant, error) {
	// Validate config path to prevent path traversal attacks
	if !filepath.IsAbs(configPath) {
		configPath = filepath.Clean(configPath)
		if strings.Contains(configPath, "..") {
			return nil, fmt.Errorf("invalid config path: path traversal detected")
		}
	}

	data, err := os.ReadFile(configPath)
	if err != nil {
		return nil, err
	}

	var merchant yapay.Merchant
	if err := json.Unmarshal(data, &merchant); err != nil {
		return nil, err
	}

	return &merchant, nil
}

func validateHandler(handler yapay.ClientHandler) error {
	// Check required methods
	if handler.GetMerchantConfig() == nil {
		return fmt.Errorf("GetMerchantConfig() returned nil")
	}

	if handler.GetMerchantID() == "" {
		return fmt.Errorf("GetMerchantID() returned empty string")
	}

	if handler.GetMerchantName() == "" {
		return fmt.Errorf("GetMerchantName() returned empty string")
	}

	// Test ValidateRequest with valid data
	testData := testing.NewTestData()
	validRequest := testData.CreateTestPaymentRequest()
	if err := handler.ValidateRequest(validRequest); err != nil {
		return fmt.Errorf("ValidateRequest failed with valid data: %v", err)
	}

	return nil
}

func runValidationTests(handler yapay.ClientHandler, verbose bool) {
	fmt.Println("\n🧪 Running validation tests...")

	testData := testing.NewTestData()

	// Test valid payment request
	validRequest := testData.CreateTestPaymentRequest()
	if err := handler.ValidateRequest(validRequest); err != nil {
		fmt.Printf("❌ Valid request failed: %v\n", err)
	} else {
		fmt.Println("✅ Valid request passed")
	}

	// Test invalid payment requests
	invalidRequests := []struct {
		name    string
		request *yapay.PaymentRequest
	}{
		{
			name: "negative amount",
			request: &yapay.PaymentRequest{
				Amount:      -100,
				Description: "Test",
				ReturnURL:   "https://example.com",
			},
		},
		{
			name: "empty description",
			request: &yapay.PaymentRequest{
				Amount:      1000,
				Description: "",
				ReturnURL:   "https://example.com",
			},
		},
		{
			name: "empty return URL",
			request: &yapay.PaymentRequest{
				Amount:      1000,
				Description: "Test",
				ReturnURL:   "",
			},
		},
	}

	for _, test := range invalidRequests {
		if err := handler.ValidateRequest(test.request); err != nil {
			if verbose {
				fmt.Printf("✅ %s correctly rejected: %v\n", test.name, err)
			}
		} else {
			fmt.Printf("❌ %s should have been rejected\n", test.name)
		}
	}

	// Test payment lifecycle
	payment := testData.CreateTestPayment()
	lifecycleTests := []struct {
		name string
		fn   func(*yapay.Payment) error
	}{
		{"HandlePaymentCreated", handler.HandlePaymentCreated},
		{"HandlePaymentSuccess", handler.HandlePaymentSuccess},
		{"HandlePaymentFailed", handler.HandlePaymentFailed},
		{"HandlePaymentCanceled", handler.HandlePaymentCanceled},
	}

	for _, test := range lifecycleTests {
		if err := test.fn(payment); err != nil {
			fmt.Printf("❌ %s failed: %v\n", test.name, err)
		} else {
			if verbose {
				fmt.Printf("✅ %s passed\n", test.name)
			}
		}
	}
}

func runSimulationTests(handler yapay.ClientHandler, verbose bool) {
	fmt.Println("\n🎭 Running simulation tests...")

	testData := testing.NewTestData()
	payment := testData.CreateTestPayment()

	// Simulate payment flow
	fmt.Println("1. Payment created...")
	if err := handler.HandlePaymentCreated(payment); err != nil {
		fmt.Printf("❌ Payment creation failed: %v\n", err)
		return
	}

	// Simulate delay
	if verbose {
		fmt.Println("   Waiting 100ms...")
		time.Sleep(100 * time.Millisecond)
	}

	// Simulate successful payment
	payment.Status = "success"
	fmt.Println("2. Payment successful...")
	if err := handler.HandlePaymentSuccess(payment); err != nil {
		fmt.Printf("❌ Payment success handling failed: %v\n", err)
		return
	}

	fmt.Println("✅ Payment simulation completed successfully")

	// Test payment generator if available
	generator := handler.GetPaymentLinkGenerator()
	if generator != nil {
		fmt.Println("\n🔗 Testing payment generator...")
		if paymentGen, ok := generator.(yapay.PaymentLinkGenerator); ok {
			request := testData.CreateTestPaymentRequest()

			fmt.Println("   Generating payment data...")
			result, err := paymentGen.GeneratePaymentData(request)
			if err != nil {
				fmt.Printf("❌ Payment data generation failed: %v\n", err)
			} else {
				fmt.Printf("✅ Payment data generated: OrderID=%s, Amount=%d\n", result.OrderID, result.Amount)
			}

			fmt.Println("   Getting payment settings...")
			settings := paymentGen.GetPaymentSettings()
			if settings != nil {
				fmt.Printf("✅ Payment settings: Currency=%s, Sandbox=%v\n", settings.Currency, settings.SandboxMode)
			}
		}
	}
}

func runBenchmarkTests(handler yapay.ClientHandler, _ bool) {
	fmt.Println("\n⚡ Running benchmark tests...")

	testData := testing.NewTestData()
	payment := testData.CreateTestPayment()
	request := testData.CreateTestPaymentRequest()

	// Benchmark payment creation
	fmt.Println("Benchmarking HandlePaymentCreated...")
	start := time.Now()
	iterations := 1000
	for i := 0; i < iterations; i++ {
		_ = handler.HandlePaymentCreated(payment)
	}
	duration := time.Since(start)
	opsPerSec := float64(iterations) / duration.Seconds()
	fmt.Printf("✅ %d operations in %v (%.0f ops/sec)\n", iterations, duration, opsPerSec)

	// Benchmark validation
	fmt.Println("Benchmarking ValidateRequest...")
	start = time.Now()
	for i := 0; i < iterations; i++ {
		_ = handler.ValidateRequest(request)
	}
	duration = time.Since(start)
	opsPerSec = float64(iterations) / duration.Seconds()
	fmt.Printf("✅ %d operations in %v (%.0f ops/sec)\n", iterations, duration, opsPerSec)

	// Benchmark payment generator if available
	generator := handler.GetPaymentLinkGenerator()
	if generator != nil {
		if paymentGen, ok := generator.(yapay.PaymentLinkGenerator); ok {
			fmt.Println("Benchmarking GeneratePaymentData...")
			start = time.Now()
			for i := 0; i < iterations; i++ {
				_, _ = paymentGen.GeneratePaymentData(request)
			}
			duration = time.Since(start)
			opsPerSec = float64(iterations) / duration.Seconds()
			fmt.Printf("✅ %d operations in %v (%.0f ops/sec)\n", iterations, duration, opsPerSec)
		}
	}
}
