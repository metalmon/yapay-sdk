package main

import (
	"fmt"
	"time"

	"github.com/metalmon/yapay-sdk"
	"github.com/sirupsen/logrus"
)

// Handler represents a simple plugin handler
type Handler struct {
	merchant  *yapay.Merchant
	logger    *logrus.Logger
	generator yapay.PaymentLinkGenerator
}

// NewHandler creates a new handler (required function)
func NewHandler(merchant *yapay.Merchant) yapay.ClientHandler {
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

// HandlePaymentCreated handles payment creation
func (h *Handler) HandlePaymentCreated(payment *yapay.Payment) error {
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

// HandlePaymentSuccess handles successful payment
func (h *Handler) HandlePaymentSuccess(payment *yapay.Payment) error {
	h.logger.WithFields(logrus.Fields{
		"payment_id": payment.ID,
		"order_id":   payment.OrderID,
		"amount":     payment.Amount,
	}).Info("Payment successful")

	// Example: Update order status, activate services, etc.
	// Notifications are sent automatically by the server based on config.yaml

	return nil
}

// HandlePaymentFailed handles failed payment
func (h *Handler) HandlePaymentFailed(payment *yapay.Payment) error {
	h.logger.WithFields(logrus.Fields{
		"payment_id": payment.ID,
		"order_id":   payment.OrderID,
		"amount":     payment.Amount,
	}).Warn("Payment failed")

	// Example: Log failure, update order status, etc.
	// Notifications are sent automatically by the server based on config.yaml

	return nil
}

// HandlePaymentCanceled handles canceled payment
func (h *Handler) HandlePaymentCanceled(payment *yapay.Payment) error {
	h.logger.WithFields(logrus.Fields{
		"payment_id": payment.ID,
		"order_id":   payment.OrderID,
		"amount":     payment.Amount,
	}).Info("Payment canceled")

	// Example: Release reserved inventory, send notification, etc.

	return nil
}

// ValidateRequest validates payment request
func (h *Handler) ValidateRequest(req *yapay.PaymentRequest) error {
	if req.Amount <= 0 {
		return fmt.Errorf("amount must be positive, got: %d", req.Amount)
	}

	if req.Description == "" {
		return fmt.Errorf("description is required")
	}

	if req.ReturnURL == "" {
		return fmt.Errorf("return URL is required")
	}

	// Example: Validate against your business rules
	// Check if amount is within limits, etc.

	h.logger.WithFields(logrus.Fields{
		"amount":      req.Amount,
		"currency":    req.Currency,
		"description": req.Description,
	}).Debug("Payment request validated")

	return nil
}

// GetMerchantConfig returns merchant configuration
func (h *Handler) GetMerchantConfig() *yapay.Merchant {
	return h.merchant
}

// GetMerchantID returns merchant ID
func (h *Handler) GetMerchantID() string {
	return h.merchant.Yandex.MerchantID
}

// GetMerchantName returns merchant name
func (h *Handler) GetMerchantName() string {
	return h.merchant.Name
}

// GetPaymentLinkGenerator returns payment link generator
func (h *Handler) GetPaymentLinkGenerator() interface{} {
	return h.generator
}

// SetPaymentLinkGenerator sets payment link generator
func (h *Handler) SetPaymentLinkGenerator(generator interface{}) {
	if gen, ok := generator.(yapay.PaymentLinkGenerator); ok {
		h.generator = gen
	}
}

// Example of how to implement payment link generation
type PaymentGenerator struct {
	merchant *yapay.Merchant
	logger   *logrus.Logger
}

// NewPaymentGenerator creates a new payment generator (optional function)
func NewPaymentGenerator(merchant *yapay.Merchant, logger *logrus.Logger) yapay.PaymentLinkGenerator {
	return &PaymentGenerator{
		merchant: merchant,
		logger:   logger,
	}
}

// GeneratePaymentData generates payment data
func (g *PaymentGenerator) GeneratePaymentData(req *yapay.PaymentRequest) (*yapay.PaymentGenerationResult, error) {
	g.logger.WithFields(logrus.Fields{
		"amount":      req.Amount,
		"description": req.Description,
	}).Info("Generating payment data")

	// Generate unique order ID
	orderID := fmt.Sprintf("order_%d_%d", time.Now().Unix(), req.Amount)

	// Prepare payment data for Yandex Pay
	paymentData := map[string]interface{}{
		"amount": map[string]interface{}{
			"value":    fmt.Sprintf("%.2f", float64(req.Amount)/100),
			"currency": req.Currency,
		},
		"confirmation": map[string]interface{}{
			"type":       "redirect",
			"return_url": req.ReturnURL,
		},
		"description": req.Description,
		"metadata":    req.Metadata,
	}

	result := &yapay.PaymentGenerationResult{
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
func (g *PaymentGenerator) ValidatePriceFromBackend(req *yapay.PaymentRequest) error {
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
func (g *PaymentGenerator) GetPaymentSettings() *yapay.PaymentSettings {
	return &yapay.PaymentSettings{
		Currency:           g.merchant.Yandex.Currency,
		SandboxMode:        g.merchant.Yandex.SandboxMode,
		AutoConfirmTimeout: 30, // 30 seconds for testing
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
