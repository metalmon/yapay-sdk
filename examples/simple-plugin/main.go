package main

import (
	"fmt"
	"time"

	yapaysdk "github.com/metalmon/yapay-sdk"
	"github.com/sirupsen/logrus"
)

// Environment constants
const (
	EnvironmentUnknown    = "unknown"
	EnvironmentSandbox    = "sandbox"
	EnvironmentProduction = "production"
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
//
// LOGGING BEST PRACTICES:
// - Server already logs: payment_id, amount, currency, status, merchant_id
// - Plugins should log: environment, order_id, metadata fields, business context
// - Use payment.Metadata for business-specific data (product_id, customer_id, etc.)
// - Avoid duplicating server logs - focus on plugin-specific information

// Handler represents a simple plugin handler
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
	}).Info("Simple plugin handler created")

	return &Handler{
		merchant: merchant,
		logger:   logger,
	}
}

// getEnvironment returns the environment with fallback to unknown
func getEnvironment(environment string) string {
	if environment == "" {
		return EnvironmentUnknown
	}
	return environment
}

// logPaymentEvent logs payment event with environment handling
func (h *Handler) logPaymentEvent(payment *yapaysdk.Payment, event string, level logrus.Level) {
	environment := getEnvironment(payment.Environment)

	// Log only plugin-specific information (server already logs payment_id, amount, etc.)
	fields := logrus.Fields{
		"environment": environment,
		"order_id":    payment.OrderID, // Plugin-specific order ID
	}

	// Add metadata if available (plugin-specific business context)
	if payment.Metadata != nil {
		if productID, exists := payment.Metadata["product_id"]; exists {
			fields["product_id"] = productID
		}
		if customerID, exists := payment.Metadata["customer_id"]; exists {
			fields["customer_id"] = customerID
		}
	}

	// Use the appropriate log level
	entry := h.logger.WithFields(fields)
	switch level {
	case logrus.WarnLevel:
		entry.Warn(event)
	case logrus.ErrorLevel:
		entry.Error(event)
	default: // InfoLevel and others
		entry.Info(event)
	}
}

// handleEnvironmentSpecificLogic handles environment-specific business logic
func (h *Handler) handleEnvironmentSpecificLogic(environment, eventType string) {
	switch environment {
	case EnvironmentSandbox:
		h.logger.WithField("event_type", eventType).Info("Processing sandbox payment - test mode")
	case EnvironmentProduction:
		h.logger.WithField("event_type", eventType).Info("Processing production payment - live mode")
	default:
		h.logger.WithField("event_type", eventType).Warn("Unknown payment environment - using default handling")
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
	environment := getEnvironment(payment.Environment)
	h.logPaymentEvent(payment, "Payment success - activating services", logrus.InfoLevel)
	h.handleEnvironmentSpecificLogic(environment, "success")

	// TODO: Implement your business logic here
	// Examples:
	// - Send confirmation email to customer
	// - Update order status in your database
	// - Activate subscription/service
	// - Update inventory
	// - Send notification to admin
	//
	// Access payment.Metadata for business-specific data:
	// - product_id, customer_id, subscription_id, etc.
	// - Use environment to determine if this is test or production

	return nil
}

// OnPaymentFailed handles failed payment (implements PaymentEventHandler)
func (h *Handler) OnPaymentFailed(payment *yapaysdk.Payment) error {
	environment := getEnvironment(payment.Environment)
	h.logPaymentEvent(payment, "Payment failed - handling failure", logrus.WarnLevel)
	h.handleEnvironmentSpecificLogic(environment, "failed")

	// TODO: Implement your failure handling logic here
	// Examples:
	// - Log failure reason for analysis
	// - Send notification to customer about failed payment
	// - Update order status to "failed"
	// - Release reserved inventory
	// - Send alert to admin
	//
	// Use environment to determine if this is test or production failure

	return nil
}

// OnPaymentCanceled handles canceled payment (implements PaymentEventHandler)
func (h *Handler) OnPaymentCanceled(payment *yapaysdk.Payment) error {
	environment := getEnvironment(payment.Environment)
	h.logPaymentEvent(payment, "Payment canceled - releasing resources", logrus.InfoLevel)
	h.handleEnvironmentSpecificLogic(environment, "canceled")

	// TODO: Implement your cancellation handling logic here
	// Examples:
	// - Release reserved inventory
	// - Cancel pending orders
	// - Send cancellation notification
	// - Update order status to "canceled"
	// - Refund any pre-authorization
	//
	// Use environment to determine if this is test or production cancellation

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
func (g *PaymentGenerator) GeneratePaymentData(
	req *yapaysdk.PaymentRequest,
) (*yapaysdk.PaymentGenerationResult, error) {
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
