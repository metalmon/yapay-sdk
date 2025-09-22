package main

import (
	"flag"
	"fmt"
	"log"
	"os"
	"plugin"

	yapaysdk "github.com/metalmon/yapay-sdk"
	"github.com/metalmon/yapay-sdk/testing"
	"gopkg.in/yaml.v3"
)

func main() {
	var (
		pluginPath = flag.String("plugin", "", "Path to plugin file (.so)")
		configPath = flag.String("config", "", "Path to YAML config file")
		verbose    = flag.Bool("verbose", false, "Enable verbose output")
		help       = flag.Bool("help", false, "Show help")
	)
	flag.Parse()

	if *help {
		showHelp()
		return
	}

	if *pluginPath == "" {
		log.Fatal("Plugin path is required. Use -plugin flag.")
	}

	// Load plugin
	fmt.Printf("Loading plugin: %s\n", *pluginPath)
	p, err := plugin.Open(*pluginPath)
	if err != nil {
		log.Fatalf("Failed to load plugin: %v", err)
	}

	// Look up NewHandler function
	newHandlerSym, err := p.Lookup("NewHandler")
	if err != nil {
		log.Fatalf("Plugin does not export NewHandler function: %v", err)
	}

	newHandler, ok := newHandlerSym.(func(*yapaysdk.Merchant) interface{})
	if !ok {
		log.Fatalf("NewHandler has wrong signature: expected func(*yapaysdk.Merchant) interface{}")
	}

	// Load config if provided
	var merchant *yapaysdk.Merchant
	if *configPath != "" {
		fmt.Printf("Loading config: %s\n", *configPath)
		merchant, err = loadConfig(*configPath)
		if err != nil {
			log.Fatalf("Failed to load config: %v", err)
		}
	} else {
		// Create test merchant
		testData := testing.NewTestData()
		merchant = testData.CreateTestMerchant()
		fmt.Println("Using test merchant configuration")
	}

	// Create handler
	fmt.Println("Creating handler...")
	handler := newHandler(merchant)

	// Validate handler
	fmt.Println("Validating handler...")
	if err := validateHandler(handler); err != nil {
		log.Fatalf("Handler validation failed: %v", err)
	}

	fmt.Println("✅ Plugin loaded and validated successfully!")

	// Run tests if verbose
	if *verbose {
		runTests(handler)
	}
}

func showHelp() {
	fmt.Printf("Plugin Debug Tool - YAPAY SDK v%s\n", yapaysdk.GetSDKVersion())
	fmt.Println("")
	fmt.Println("Usage:")
	fmt.Println("  plugin-debug -plugin <plugin.so> [-config <config.yaml>] [-verbose]")
	fmt.Println("")
	fmt.Println("Options:")
	fmt.Println("  -plugin string")
	fmt.Println("        Path to plugin file (.so)")
	fmt.Println("  -config string")
	fmt.Println("        Path to YAML config file")
	fmt.Println("  -verbose")
	fmt.Println("        Enable verbose output and run tests")
	fmt.Println("  -help")
	fmt.Println("        Show this help message")
	fmt.Println("")
	fmt.Println("Examples:")
	fmt.Println("  plugin-debug -plugin ./my-plugin.so")
	fmt.Println("  plugin-debug -plugin ./my-plugin.so -config ./config.yaml -verbose")
}

func loadConfig(configPath string) (*yapaysdk.Merchant, error) {
	data, err := os.ReadFile(configPath)
	if err != nil {
		return nil, fmt.Errorf("failed to read config file: %v", err)
	}

	var merchant yapaysdk.Merchant
	if err := yaml.Unmarshal(data, &merchant); err != nil {
		return nil, fmt.Errorf("failed to parse config: %v", err)
	}

	return &merchant, nil
}

func validateHandler(handler interface{}) error {
	// Check if handler implements PaymentEventHandler interface
	if _, ok := handler.(yapaysdk.PaymentEventHandler); !ok {
		return fmt.Errorf("handler does not implement PaymentEventHandler interface")
	}

	// Check if handler implements VersionedPlugin interface
	if _, ok := handler.(yapaysdk.VersionedPlugin); !ok {
		return fmt.Errorf("handler does not implement VersionedPlugin interface")
	}

	// Test version reporting
	versionedHandler := handler.(yapaysdk.VersionedPlugin)
	sdkVersion := versionedHandler.GetSDKVersion()
	if sdkVersion == "" {
		return fmt.Errorf("GetSDKVersion() returned empty string")
	}

	fmt.Printf("✅ Handler reports SDK version: %s\n", sdkVersion)

	return nil
}

func runTests(handler interface{}) {
	fmt.Println("\n🧪 Running tests...")

	// Test interface implementations
	if _, ok := handler.(yapaysdk.PaymentEventHandler); ok {
		fmt.Println("✅ PaymentEventHandler interface implemented")
	} else {
		fmt.Println("❌ PaymentEventHandler interface not implemented")
	}

	if _, ok := handler.(yapaysdk.VersionedPlugin); ok {
		fmt.Println("✅ VersionedPlugin interface implemented")
	} else {
		fmt.Println("❌ VersionedPlugin interface not implemented")
	}

	// Test payment event handlers
	fmt.Println("\n🎭 Testing payment event handlers...")
	testData := testing.NewTestData()
	payment := testData.CreateTestPayment()

	eventHandler := handler.(yapaysdk.PaymentEventHandler)

	if err := eventHandler.OnPaymentCreated(payment); err != nil {
		fmt.Printf("❌ OnPaymentCreated failed: %v\n", err)
	} else {
		fmt.Println("✅ OnPaymentCreated passed")
	}

	if err := eventHandler.OnPaymentSuccess(payment); err != nil {
		fmt.Printf("❌ OnPaymentSuccess failed: %v\n", err)
	} else {
		fmt.Println("✅ OnPaymentSuccess passed")
	}

	if err := eventHandler.OnPaymentFailed(payment); err != nil {
		fmt.Printf("❌ OnPaymentFailed failed: %v\n", err)
	} else {
		fmt.Println("✅ OnPaymentFailed passed")
	}

	if err := eventHandler.OnPaymentCanceled(payment); err != nil {
		fmt.Printf("❌ OnPaymentCanceled failed: %v\n", err)
	} else {
		fmt.Println("✅ OnPaymentCanceled passed")
	}

	fmt.Println("\n✅ All tests completed!")
}
