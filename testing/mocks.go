package testing

import (
	"time"

	"github.com/metalmon/yapay-sdk"
)

// MockClientHandler is a mock implementation of ClientHandler for testing
type MockClientHandler struct {
	Merchant             *yapay.Merchant
	PaymentCreatedCalls  []*yapay.Payment
	PaymentSuccessCalls  []*yapay.Payment
	PaymentFailedCalls   []*yapay.Payment
	PaymentCanceledCalls []*yapay.Payment
	ValidateRequestCalls []*yapay.PaymentRequest
	ValidateRequestError error
	PaymentGenerator     yapay.PaymentLinkGenerator
}

// NewMockClientHandler creates a new mock client handler
func NewMockClientHandler() *MockClientHandler {
	return &MockClientHandler{
		PaymentCreatedCalls:  make([]*yapay.Payment, 0),
		PaymentSuccessCalls:  make([]*yapay.Payment, 0),
		PaymentFailedCalls:   make([]*yapay.Payment, 0),
		PaymentCanceledCalls: make([]*yapay.Payment, 0),
		ValidateRequestCalls: make([]*yapay.PaymentRequest, 0),
	}
}

// SetMerchant sets the merchant configuration
func (m *MockClientHandler) SetMerchant(merchant *yapay.Merchant) {
	m.Merchant = merchant
}

// SetValidateRequestError sets the error to return from ValidateRequest
func (m *MockClientHandler) SetValidateRequestError(err error) {
	m.ValidateRequestError = err
}

// HandlePaymentCreated records the call and returns nil
func (m *MockClientHandler) HandlePaymentCreated(payment *yapay.Payment) error {
	m.PaymentCreatedCalls = append(m.PaymentCreatedCalls, payment)
	return nil
}

// HandlePaymentSuccess records the call and returns nil
func (m *MockClientHandler) HandlePaymentSuccess(payment *yapay.Payment) error {
	m.PaymentSuccessCalls = append(m.PaymentSuccessCalls, payment)
	return nil
}

// HandlePaymentFailed records the call and returns nil
func (m *MockClientHandler) HandlePaymentFailed(payment *yapay.Payment) error {
	m.PaymentFailedCalls = append(m.PaymentFailedCalls, payment)
	return nil
}

// HandlePaymentCanceled records the call and returns nil
func (m *MockClientHandler) HandlePaymentCanceled(payment *yapay.Payment) error {
	m.PaymentCanceledCalls = append(m.PaymentCanceledCalls, payment)
	return nil
}

// ValidateRequest records the call and returns the configured error
func (m *MockClientHandler) ValidateRequest(req *yapay.PaymentRequest) error {
	m.ValidateRequestCalls = append(m.ValidateRequestCalls, req)
	return m.ValidateRequestError
}

// GetMerchantConfig returns the configured merchant
func (m *MockClientHandler) GetMerchantConfig() *yapay.Merchant {
	return m.Merchant
}

// GetMerchantID returns the merchant ID
func (m *MockClientHandler) GetMerchantID() string {
	if m.Merchant != nil {
		return m.Merchant.Yandex.MerchantID
	}
	return ""
}

// GetMerchantName returns the merchant name
func (m *MockClientHandler) GetMerchantName() string {
	if m.Merchant != nil {
		return m.Merchant.Name
	}
	return ""
}

// GetPaymentLinkGenerator returns the configured generator
func (m *MockClientHandler) GetPaymentLinkGenerator() interface{} {
	return m.PaymentGenerator
}

// SetPaymentLinkGenerator sets the payment generator
func (m *MockClientHandler) SetPaymentLinkGenerator(generator interface{}) {
	if gen, ok := generator.(yapay.PaymentLinkGenerator); ok {
		m.PaymentGenerator = gen
	}
}

// Reset clears all recorded calls
func (m *MockClientHandler) Reset() {
	m.PaymentCreatedCalls = make([]*yapay.Payment, 0)
	m.PaymentSuccessCalls = make([]*yapay.Payment, 0)
	m.PaymentFailedCalls = make([]*yapay.Payment, 0)
	m.PaymentCanceledCalls = make([]*yapay.Payment, 0)
	m.ValidateRequestCalls = make([]*yapay.PaymentRequest, 0)
	m.ValidateRequestError = nil
}

// GetCallCounts returns the number of calls for each method
func (m *MockClientHandler) GetCallCounts() map[string]int {
	return map[string]int{
		"HandlePaymentCreated":  len(m.PaymentCreatedCalls),
		"HandlePaymentSuccess":  len(m.PaymentSuccessCalls),
		"HandlePaymentFailed":   len(m.PaymentFailedCalls),
		"HandlePaymentCanceled": len(m.PaymentCanceledCalls),
		"ValidateRequest":       len(m.ValidateRequestCalls),
	}
}

// MockPaymentGenerator is a mock implementation of PaymentLinkGenerator for testing
type MockPaymentGenerator struct {
	GeneratePaymentDataCalls []*yapay.PaymentRequest
	ValidatePriceCalls       []*yapay.PaymentRequest
	GetSettingsCalls         int
	CustomizePayloadCalls    []map[string]interface{}

	GeneratePaymentDataResult *yapay.PaymentGenerationResult
	GeneratePaymentDataError  error
	ValidatePriceError        error
	PaymentSettings           *yapay.PaymentSettings
	CustomizePayloadError     error
}

// NewMockPaymentGenerator creates a new mock payment generator
func NewMockPaymentGenerator() *MockPaymentGenerator {
	return &MockPaymentGenerator{
		GeneratePaymentDataCalls: make([]*yapay.PaymentRequest, 0),
		ValidatePriceCalls:       make([]*yapay.PaymentRequest, 0),
		CustomizePayloadCalls:    make([]map[string]interface{}, 0),
		PaymentSettings: &yapay.PaymentSettings{
			Currency:           "RUB",
			SandboxMode:        true,
			AutoConfirmTimeout: 30,
			CustomFields:       make(map[string]interface{}),
		},
	}
}

// SetGeneratePaymentDataResult sets the result to return from GeneratePaymentData
func (m *MockPaymentGenerator) SetGeneratePaymentDataResult(result *yapay.PaymentGenerationResult, err error) {
	m.GeneratePaymentDataResult = result
	m.GeneratePaymentDataError = err
}

// SetValidatePriceError sets the error to return from ValidatePriceFromBackend
func (m *MockPaymentGenerator) SetValidatePriceError(err error) {
	m.ValidatePriceError = err
}

// SetPaymentSettings sets the settings to return from GetPaymentSettings
func (m *MockPaymentGenerator) SetPaymentSettings(settings *yapay.PaymentSettings) {
	m.PaymentSettings = settings
}

// SetCustomizePayloadError sets the error to return from CustomizeYandexPayload
func (m *MockPaymentGenerator) SetCustomizePayloadError(err error) {
	m.CustomizePayloadError = err
}

// GeneratePaymentData records the call and returns the configured result
func (m *MockPaymentGenerator) GeneratePaymentData(req *yapay.PaymentRequest) (*yapay.PaymentGenerationResult, error) {
	m.GeneratePaymentDataCalls = append(m.GeneratePaymentDataCalls, req)
	return m.GeneratePaymentDataResult, m.GeneratePaymentDataError
}

// ValidatePriceFromBackend records the call and returns the configured error
func (m *MockPaymentGenerator) ValidatePriceFromBackend(req *yapay.PaymentRequest) error {
	m.ValidatePriceCalls = append(m.ValidatePriceCalls, req)
	return m.ValidatePriceError
}

// GetPaymentSettings records the call and returns the configured settings
func (m *MockPaymentGenerator) GetPaymentSettings() *yapay.PaymentSettings {
	m.GetSettingsCalls++
	return m.PaymentSettings
}

// CustomizeYandexPayload records the call and returns the configured error
func (m *MockPaymentGenerator) CustomizeYandexPayload(payload map[string]interface{}) error {
	m.CustomizePayloadCalls = append(m.CustomizePayloadCalls, payload)
	return m.CustomizePayloadError
}

// Reset clears all recorded calls
func (m *MockPaymentGenerator) Reset() {
	m.GeneratePaymentDataCalls = make([]*yapay.PaymentRequest, 0)
	m.ValidatePriceCalls = make([]*yapay.PaymentRequest, 0)
	m.GetSettingsCalls = 0
	m.CustomizePayloadCalls = make([]map[string]interface{}, 0)
	m.GeneratePaymentDataResult = nil
	m.GeneratePaymentDataError = nil
	m.ValidatePriceError = nil
	m.CustomizePayloadError = nil
}

// GetCallCounts returns the number of calls for each method
func (m *MockPaymentGenerator) GetCallCounts() map[string]int {
	return map[string]int{
		"GeneratePaymentData":      len(m.GeneratePaymentDataCalls),
		"ValidatePriceFromBackend": len(m.ValidatePriceCalls),
		"GetPaymentSettings":       m.GetSettingsCalls,
		"CustomizeYandexPayload":   len(m.CustomizePayloadCalls),
	}
}

// TestData contains helper functions for creating test data
type TestData struct{}

// NewTestData creates a new TestData instance
func NewTestData() *TestData {
	return &TestData{}
}

// CreateTestMerchant creates a test merchant configuration
func (t *TestData) CreateTestMerchant() *yapay.Merchant {
	return &yapay.Merchant{
		ID:          "test-merchant-id",
		Name:        "Test Merchant",
		Description: "Test merchant for unit testing",
		Domain:      "test.example.com",
		Enabled:     true,
		SandboxMode: true,
		Security: yapay.SecurityConfig{
			RequestEnforcement: "monitor",
			RateLimit:          100,
			CORS: yapay.CORSConfig{
				Origins: []string{"https://test.example.com"},
			},
		},
		Metadata: map[string]interface{}{
			"version": "1.0.0",
			"author":  "Test",
		},
		Yandex: yapay.YandexConfig{
			MerchantID:  "test-merchant-id",
			SecretKey:   "test-secret-key",
			SandboxMode: true,
			Currency:    "RUB",
		},
		Notifications: yapay.NotificationConfig{
			Telegram: yapay.TelegramConfig{
				Enabled:  true,
				ChatID:   "test-chat-id",
				BotToken: "test-bot-token",
			},
			Email: yapay.EmailConfig{
				Enabled: false,
			},
		},
		FieldLabels: yapay.FieldLabels{
			"order_id": "Order ID",
			"amount":   "Amount",
		},
	}
}

// CreateTestPayment creates a test payment
func (t *TestData) CreateTestPayment() *yapay.Payment {
	return &yapay.Payment{
		ID:          "test-payment-id",
		OrderID:     "test-order-id",
		Amount:      1000,
		Currency:    "RUB",
		Description: "Test payment",
		Status:      "created",
		ReturnURL:   "https://test.example.com/return",
		Metadata: map[string]interface{}{
			"test": true,
		},
		CreatedAt: time.Now().Format(time.RFC3339),
		UpdatedAt: time.Now().Format(time.RFC3339),
	}
}

// CreateTestPaymentRequest creates a test payment request
func (t *TestData) CreateTestPaymentRequest() *yapay.PaymentRequest {
	return &yapay.PaymentRequest{
		Amount:      1000,
		Currency:    "RUB",
		Description: "Test payment request",
		ReturnURL:   "https://test.example.com/return",
		Metadata: map[string]interface{}{
			"test": true,
		},
	}
}

// CreateTestPaymentGenerationResult creates a test payment generation result
func (t *TestData) CreateTestPaymentGenerationResult() *yapay.PaymentGenerationResult {
	return &yapay.PaymentGenerationResult{
		PaymentData: map[string]interface{}{
			"order_id":    "test-order-id",
			"amount":      1000,
			"currency":    "RUB",
			"description": "Test payment",
			"return_url":  "https://test.example.com/return",
		},
		OrderID:     "test-order-id",
		Amount:      1000,
		Currency:    "RUB",
		Description: "Test payment",
		ReturnURL:   "https://test.example.com/return",
		Metadata: map[string]interface{}{
			"test": true,
		},
	}
}
