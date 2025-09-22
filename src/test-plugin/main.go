package main

import (
	"fmt"
	"time"

	yapaysdk "github.com/metalmon/yapay-sdk"
	"github.com/sirupsen/logrus"
)

// This example demonstrates how to work with the Environment field in Payment struct.
// The Environment field allows plugins to determine whether a payment came from
// production or sandbox environment, enabling different handling logic.
//
// Environment values:
// - "production": Real payment from production environment
// - "sandbox": Test payment from sandbox environment
// - "": Empty for older webhooks (fallback to "unknown")
//
// This is particularly useful for:
// - Different logging levels for test vs production payments
// - Conditional service activation (only for production payments)
// - Separate notification handling for test payments
// - Environment-specific business logic

// Handler represents a test-plugin plugin handler
type Handler struct {
	merchant *yapaysdk.Merchant
	logger   *logrus.Logger
	// generator field removed as it's not used in PaymentEventHandler interface
}

// NewHandler creates a new handler (required function)
func NewHandler(merchant *yapaysdk.Merchant) interface{} {
	logger := logrus.New()
	logger.WithFields(logrus.Fields{
		"merchant_id": merchant.Yandex.MerchantID,
		"name":        merchant.Name,
	}).Info("TestPlugin plugin handler created")

	return &Handler{
		merchant: merchant,
		logger:   logger,
	}
}

// OnPaymentCreated handles payment creation (implements PaymentEventHandler)
func (h *Handler) OnPaymentCreated(payment *yapaysdk.Payment) error {
	h.logger.WithFields(logrus.Fields{
		"payment_id":  payment.ID,
		"order_id":    payment.OrderID,
		"amount":      payment.Amount,
		"currency":    payment.Currency,
		"description": payment.Description,
	}).Info("Payment created")

	// Example: Save to database, send notification, etc.
	// This is where you implement your business logic

	return nil
}

// OnPaymentSuccess handles successful payment (implements PaymentEventHandler)
func (h *Handler) OnPaymentSuccess(payment *yapaysdk.Payment) error {
	// Determine environment for different handling
	environment := payment.Environment
	if environment == "" {
		environment = "unknown" // Fallback for older webhooks without Environment field
	}

	h.logger.WithFields(logrus.Fields{
		"payment_id":  payment.ID,
		"order_id":    payment.OrderID,
		"amount":      payment.Amount,
		"environment": environment,
	}).Info("Payment successful")

	// Handle different environments
	switch environment {
	case "sandbox":
		h.logger.Info("Processing sandbox payment - test mode")
		// Example: Log test payment, don't activate real services
		// This is a test payment, so we might want to handle it differently

	case "production":
		h.logger.Info("Processing production payment - live mode")
		// Example: Update order status, activate services, etc.
		// This is a real payment, so activate actual services

	default:
		h.logger.Warn("Unknown payment environment - using default handling")
		// Fallback for unknown environments
	}

	// Common logic for all environments
	// Example: Update order status, send notifications, etc.
	// Notifications are sent automatically by the server based on config.yaml

	return nil
}

// OnPaymentFailed handles failed payment (implements PaymentEventHandler)
func (h *Handler) OnPaymentFailed(payment *yapaysdk.Payment) error {
	environment := payment.Environment
	if environment == "" {
		environment = "unknown"
	}

	h.logger.WithFields(logrus.Fields{
		"payment_id":  payment.ID,
		"order_id":    payment.OrderID,
		"amount":      payment.Amount,
		"environment": environment,
	}).Warn("Payment failed")

	// Handle different environments for failed payments
	switch environment {
	case "sandbox":
		h.logger.Info("Sandbox payment failed - test mode")
		// Example: Log test failure, don't send real notifications

	case "production":
		h.logger.Info("Production payment failed - live mode")
		// Example: Log failure, update order status, send notifications, etc.

	default:
		h.logger.Warn("Unknown payment environment - using default handling")
	}

	// Common logic for all environments
	// Example: Log failure, update order status, etc.
	// Notifications are sent automatically by the server based on config.yaml

	return nil
}

// OnPaymentCanceled handles canceled payment (implements PaymentEventHandler)
func (h *Handler) OnPaymentCanceled(payment *yapaysdk.Payment) error {
	environment := payment.Environment
	if environment == "" {
		environment = "unknown"
	}

	h.logger.WithFields(logrus.Fields{
		"payment_id":  payment.ID,
		"order_id":    payment.OrderID,
		"amount":      payment.Amount,
		"environment": environment,
	}).Info("Payment canceled")

	// Handle different environments for canceled payments
	switch environment {
	case "sandbox":
		h.logger.Info("Sandbox payment canceled - test mode")
		// Example: Log test cancellation, don't release real inventory

	case "production":
		h.logger.Info("Production payment canceled - live mode")
		// Example: Release reserved inventory, send notification, etc.

	default:
		h.logger.Warn("Unknown payment environment - using default handling")
	}

	// Common logic for all environments
	// Example: Release reserved inventory, send notification, etc.

	return nil
}

// GetSDKVersion returns the SDK version this plugin was built against (implements VersionedPlugin)
func (h *Handler) GetSDKVersion() string {
	return yapaysdk.GetSDKVersion()
}

// Example of how to implement payment link generation
type PaymentGenerator struct {
	merchant *yapaysdk.Merchant
	logger   *logrus.Logger
}

// NewPaymentGenerator creates a new payment generator (optional function)
func NewPaymentGenerator(merchant *yapaysdk.Merchant, logger *logrus.Logger) yapaysdk.PaymentLinkGenerator {
	return &PaymentGenerator{
		merchant: merchant,
		logger:   logger,
	}
}

// GeneratePaymentData generates payment data
func (g *PaymentGenerator) GeneratePaymentData(req *yapaysdk.PaymentRequest) (*yapaysdk.PaymentGenerationResult, error) {
	g.logger.WithFields(logrus.Fields{
		"amount":      req.Amount,
		"description": req.Description,
	}).Info("Generating payment data")

	// Generate unique order ID
	orderID := fmt.Sprintf("order_%d_%d", time.Now().Unix(), req.Amount)

	// Prepare payment data for Yandex Pay
	paymentData := map[string]interface{}{
		"amount": map[string]interface{}{
			"value":    fmt.Sprintf("%.2f", float64(req.Amount)/100.0), //nolint:mnd // Convert kopecks to rubles
			"currency": req.Currency,
		},
		"confirmation": map[string]interface{}{
			"type":       "redirect",
			"return_url": req.ReturnURL,
		},
		"description": req.Description,
		"metadata":    req.Metadata,
	}

	result := &yapaysdk.PaymentGenerationResult{
		PaymentData: paymentData,
		OrderID:     orderID,
		Amount:      req.Amount,
		Currency:    req.Currency,
		Description: req.Description,
		ReturnURL:   req.ReturnURL,
		Metadata:    req.Metadata,
	}

	g.logger.WithFields(logrus.Fields{
		"order_id": orderID,
		"amount":   req.Amount,
		"currency": req.Currency,
	}).Info("Payment data generated")

	return result, nil
}

// ValidatePriceFromBackend validates price from backend
func (g *PaymentGenerator) ValidatePriceFromBackend(req *yapaysdk.PaymentRequest) error {
	g.logger.WithField("amount", req.Amount).Debug("Price validation skipped - using frontend data as-is")

	// Example: Check price against your backend
	// This is where you would make API calls to your backend
	// to validate the price, check inventory, etc.
	//
	// Uncomment and implement if you need backend validation:
	//
	// productID, exists := req.Metadata["product_id"]
	// if !exists {
	//     return nil // Skip validation if no product_id
	// }
	//
	// expectedPrice, err := g.getProductPrice(productID.(string))
	// if err != nil {
	//     return fmt.Errorf("failed to get product price: %w", err)
	// }
	//
	// if req.Amount != expectedPrice {
	//     return fmt.Errorf("price mismatch: expected %d, got %d", expectedPrice, req.Amount)
	// }

	return nil
}

// GetPaymentSettings returns payment settings
func (g *PaymentGenerator) GetPaymentSettings() *yapaysdk.PaymentSettings {
	return &yapaysdk.PaymentSettings{
		Currency:           g.merchant.Yandex.Currency,
		SandboxMode:        g.merchant.Yandex.SandboxMode,
		AutoConfirmTimeout: 30, //nolint:mnd // 30 seconds for testing
		CustomFields: map[string]interface{}{
			"merchant_name": g.merchant.Name,
			"domain":        g.merchant.Domain,
		},
	}
}

// CustomizeYandexPayload customizes Yandex Pay payload
func (g *PaymentGenerator) CustomizeYandexPayload(payload map[string]interface{}) error {
	g.logger.Debug("Customizing Yandex Pay payload")

	// Add merchant information to payload
	payload["merchant_name"] = g.merchant.Name
	payload["domain"] = g.merchant.Domain

	// Example: Add receipt information if needed
	// Uncomment and customize if you need receipt:
	//
	// if metadata, exists := payload["metadata"].(map[string]interface{}); exists {
	//     if userEmail, exists := metadata["user_email"]; exists {
	//         payload["receipt"] = map[string]interface{}{
	//             "customer": map[string]interface{}{
	//                 "email": userEmail,
	//             },
	//             "items": []map[string]interface{}{
	//                 {
	//                     "description": payload["description"],
	//                     "amount":       payload["amount"],
	//                     "quantity":    "1",
	//                     "vat_code":    "1", // НДС 20%
	//                 },
	//             },
	//         }
	//     }
	// }

	return nil
}
