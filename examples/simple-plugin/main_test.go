package main

import (
	"fmt"
	"testing"

	"github.com/metalmon/yapay-sdk"
	yapaytesting "github.com/metalmon/yapay-sdk/testing"
	"github.com/sirupsen/logrus"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestNewHandler(t *testing.T) {
	// Create test merchant
	testData := yapaytesting.NewTestData()
	merchant := testData.CreateTestMerchant()

	// Create handler
	handler := NewHandler(merchant)

	// Verify handler implements interfaces
	handlerTyped := handler.(*Handler)
	var _ yapay.PaymentEventHandler = handlerTyped
	var _ yapay.VersionedPlugin = handlerTyped
	assert.Equal(t, yapay.GetSDKVersion(), handlerTyped.GetSDKVersion())
}

func TestHandler_OnPaymentCreated(t *testing.T) {
	// Create test data
	testData := yapaytesting.NewTestData()
	merchant := testData.CreateTestMerchant()
	payment := testData.CreateTestPayment()

	// Create handler with test logger to capture logs
	logger := logrus.New()
	logger.SetLevel(logrus.InfoLevel)
	handler := &Handler{
		merchant: merchant,
		logger:   logger,
	}

	// Handle payment created
	err := handler.OnPaymentCreated(payment)

	// Verify no error
	assert.NoError(t, err)

	// Verify handler state
	assert.NotNil(t, handler.merchant)
	assert.NotNil(t, handler.logger)
	assert.Equal(t, merchant, handler.merchant)
}

func TestHandler_OnPaymentSuccess(t *testing.T) {
	// Create test data
	testData := yapaytesting.NewTestData()
	merchant := testData.CreateTestMerchant()
	payment := testData.CreateTestPayment()
	payment.Status = "success"

	// Create handler
	handler := NewHandler(merchant).(*Handler)

	// Handle payment success
	err := handler.OnPaymentSuccess(payment)

	// Verify no error
	assert.NoError(t, err)
}

func TestHandler_OnPaymentFailed(t *testing.T) {
	// Create test data
	testData := yapaytesting.NewTestData()
	merchant := testData.CreateTestMerchant()
	payment := testData.CreateTestPayment()
	payment.Status = "failed"

	// Create handler
	handler := NewHandler(merchant).(*Handler)

	// Handle payment failed
	err := handler.OnPaymentFailed(payment)

	// Verify no error
	assert.NoError(t, err)
}

func TestHandler_OnPaymentCanceled(t *testing.T) {
	// Create test data
	testData := yapaytesting.NewTestData()
	merchant := testData.CreateTestMerchant()
	payment := testData.CreateTestPayment()
	payment.Status = "canceled"

	// Create handler
	handler := NewHandler(merchant).(*Handler)

	// Handle payment canceled
	err := handler.OnPaymentCanceled(payment)

	// Verify no error
	assert.NoError(t, err)
}

// TestHandler_ValidateRequest removed - method no longer exists
func TestHandler_ValidateRequest_Removed(t *testing.T) {
	t.Skip("ValidateRequest method was removed from PaymentEventHandler interface")
	/* testCases := []struct {
		name          string
		request       *yapay.PaymentRequest
		expectedError bool
		errorMessage  string
	}{
		{
			name: "valid request",
			request: &yapay.PaymentRequest{
				Amount:      1000,
				Description: "Valid payment",
				ReturnURL:   "https://example.com/return",
				Currency:    "RUB",
			},
			expectedError: false,
		},
		{
			name: "negative amount",
			request: &yapay.PaymentRequest{
				Amount:      -100,
				Description: "Invalid payment",
				ReturnURL:   "https://example.com/return",
			},
			expectedError: true,
			errorMessage:  "amount must be positive, got: -100",
		},
		{
			name: "zero amount",
			request: &yapay.PaymentRequest{
				Amount:      0,
				Description: "Invalid payment",
				ReturnURL:   "https://example.com/return",
			},
			expectedError: true,
			errorMessage:  "amount must be positive, got: 0",
		},
		{
			name: "empty description",
			request: &yapay.PaymentRequest{
				Amount:      1000,
				Description: "",
				ReturnURL:   "https://example.com/return",
			},
			expectedError: true,
			errorMessage:  "description is required",
		},
		// Return URL validation removed - may be optional in Yandex Pay
		// URL can be configured in merchant's personal account
		{
			name: "large amount",
			request: &yapay.PaymentRequest{
				Amount:      100000000, // 1 million rubles
				Description: "Large payment",
				ReturnURL:   "https://example.com/return",
			},
			expectedError: false, // Should be valid
		},
	}

	// Create test merchant
	testData := yapaytesting.NewTestData()
	merchant := testData.CreateTestMerchant()

	// Create handler
	handler := NewHandler(merchant).(*Handler)

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			err := handler.ValidateRequest(tc.request)

			if tc.expectedError {
				assert.Error(t, err)
				assert.Contains(t, err.Error(), tc.errorMessage)
			} else {
				assert.NoError(t, err)
			}
		})
	}
	*/
}

// TestHandler_GetPaymentLinkGenerator removed - method no longer exists
func TestHandler_GetPaymentLinkGenerator_Removed(t *testing.T) {
	t.Skip("GetPaymentLinkGenerator method was removed from PaymentEventHandler interface")
	/* // Create test merchant
		testData := yapaytesting.NewTestData()
		merchant := testData.CreateTestMerchant()

		// Create handler
		handler := NewHandler(merchant).(*Handler)

		// Initially should be nil
		generator := handler.GetPaymentLinkGenerator()
		assert.Nil(t, generator)
	}

	func TestHandler_SetPaymentLinkGenerator(t *testing.T) {
		// Create test merchant
		testData := yapaytesting.NewTestData()
		merchant := testData.CreateTestMerchant()

		// Create handler
		handler := NewHandler(merchant).(*Handler)

		// Create mock generator
		mockGenerator := yapaytesting.NewMockPaymentGenerator()

		// Set generator
		handler.SetPaymentLinkGenerator(mockGenerator)

		// Verify generator was set
		generator := handler.GetPaymentLinkGenerator()
		assert.NotNil(t, generator)
		assert.Equal(t, mockGenerator, generator)
	*/
}

func TestNewPaymentGenerator(t *testing.T) {
	// Create test merchant
	testData := yapaytesting.NewTestData()
	merchant := testData.CreateTestMerchant()

	// Create payment generator
	generator := NewPaymentGenerator(merchant, nil)

	// Verify generator implements interface
	var _ yapay.PaymentLinkGenerator = generator

	// Verify generator properties
	assert.Equal(t, merchant, generator.(*PaymentGenerator).merchant)
}

func TestPaymentGenerator_GeneratePaymentData(t *testing.T) {
	// Create test data
	testData := yapaytesting.NewTestData()
	merchant := testData.CreateTestMerchant()
	request := testData.CreateTestPaymentRequest()

	// Create payment generator with logger
	logger := logrus.New()
	generator := NewPaymentGenerator(merchant, logger).(*PaymentGenerator)

	// Generate payment data
	result, err := generator.GeneratePaymentData(request)

	// Verify no error
	require.NoError(t, err)
	require.NotNil(t, result)

	// Verify result properties
	assert.NotEmpty(t, result.OrderID)
	assert.Equal(t, request.Amount, result.Amount)
	assert.Equal(t, request.Currency, result.Currency)
	assert.Equal(t, request.Description, result.Description)
	assert.Equal(t, request.ReturnURL, result.ReturnURL)
	assert.Equal(t, request.Metadata, result.Metadata)

	// Verify order ID format - should be "order_{timestamp}_{amount}"
	assert.Contains(t, result.OrderID, "order_")
	assert.Contains(t, result.OrderID, "_")
	assert.Contains(t, result.OrderID, fmt.Sprintf("%d", request.Amount))

	// Verify PaymentData structure for Yandex Pay
	require.NotNil(t, result.PaymentData)

	// Check amount structure
	amountData, exists := result.PaymentData["amount"].(map[string]interface{})
	require.True(t, exists)
	assert.Equal(t, fmt.Sprintf("%.2f", float64(request.Amount)/100), amountData["value"])
	assert.Equal(t, request.Currency, amountData["currency"])

	// Check confirmation structure
	confirmationData, exists := result.PaymentData["confirmation"].(map[string]interface{})
	require.True(t, exists)
	assert.Equal(t, "redirect", confirmationData["type"])
	assert.Equal(t, request.ReturnURL, confirmationData["return_url"])

	// Check other fields
	assert.Equal(t, request.Description, result.PaymentData["description"])
	assert.Equal(t, request.Metadata, result.PaymentData["metadata"])
}

func TestPaymentGenerator_GeneratePaymentData_OrderIDFormat(t *testing.T) {
	// Create test data
	testData := yapaytesting.NewTestData()
	merchant := testData.CreateTestMerchant()
	request := testData.CreateTestPaymentRequest()

	// Create payment generator
	logger := logrus.New()
	generator := NewPaymentGenerator(merchant, logger).(*PaymentGenerator)

	// Generate payment data
	result, err := generator.GeneratePaymentData(request)
	require.NoError(t, err)

	// Verify order ID format - should be "order_{timestamp}_{amount}"
	assert.Contains(t, result.OrderID, "order_")
	assert.Contains(t, result.OrderID, "_")
	assert.Contains(t, result.OrderID, fmt.Sprintf("%d", request.Amount))

	// Verify order ID contains timestamp (numeric part)
	assert.True(t, len(result.OrderID) > 10, "Order ID should contain timestamp")

	// Verify timestamp is reasonable (not too old, not in future)
	// This is a basic sanity check - order ID should be long enough to contain timestamp
	assert.True(t, len(result.OrderID) >= 20, "Order ID should contain timestamp and amount")
}

func TestPaymentGenerator_ValidatePriceFromBackend(t *testing.T) {
	// Create test data
	testData := yapaytesting.NewTestData()
	merchant := testData.CreateTestMerchant()
	request := testData.CreateTestPaymentRequest()

	// Create payment generator with logger
	logger := logrus.New()
	generator := NewPaymentGenerator(merchant, logger).(*PaymentGenerator)

	// Validate price (should not error in this simple implementation)
	err := generator.ValidatePriceFromBackend(request)

	// Verify no error
	assert.NoError(t, err)
}

func TestPaymentGenerator_GetPaymentSettings(t *testing.T) {
	// Create test data
	testData := yapaytesting.NewTestData()
	merchant := testData.CreateTestMerchant()

	// Create payment generator with logger
	logger := logrus.New()
	generator := NewPaymentGenerator(merchant, logger).(*PaymentGenerator)

	// Get payment settings
	settings := generator.GetPaymentSettings()

	// Verify settings
	require.NotNil(t, settings)
	assert.Equal(t, merchant.Yandex.Currency, settings.Currency)
	assert.Equal(t, merchant.Yandex.SandboxMode, settings.SandboxMode)
	assert.Equal(t, 30, settings.AutoConfirmTimeout)

	// Verify custom fields
	require.NotNil(t, settings.CustomFields)
	assert.Equal(t, merchant.Name, settings.CustomFields["merchant_name"])
	assert.Equal(t, merchant.Domain, settings.CustomFields["domain"])

	// Verify all required fields are present
	assert.NotEmpty(t, settings.Currency)
	assert.NotNil(t, settings.CustomFields)
}

func TestPaymentGenerator_CustomizeYandexPayload(t *testing.T) {
	// Create test data
	testData := yapaytesting.NewTestData()
	merchant := testData.CreateTestMerchant()

	// Create payment generator with logger
	logger := logrus.New()
	generator := NewPaymentGenerator(merchant, logger).(*PaymentGenerator)

	// Create test payload
	payload := map[string]interface{}{
		"amount":      1000,
		"description": "Test payment",
		"currency":    "RUB",
	}

	// Customize payload
	err := generator.CustomizeYandexPayload(payload)

	// Verify no error
	assert.NoError(t, err)

	// Verify payload was customized with merchant information
	assert.Equal(t, merchant.Name, payload["merchant_name"])
	assert.Equal(t, merchant.Domain, payload["domain"])

	// Verify original fields are preserved
	assert.Equal(t, 1000, payload["amount"])
	assert.Equal(t, "Test payment", payload["description"])
	assert.Equal(t, "RUB", payload["currency"])
}

func TestPaymentGenerator_CustomizeYandexPayload_EmptyPayload(t *testing.T) {
	// Create test data
	testData := yapaytesting.NewTestData()
	merchant := testData.CreateTestMerchant()

	// Create payment generator with logger
	logger := logrus.New()
	generator := NewPaymentGenerator(merchant, logger).(*PaymentGenerator)

	// Create empty payload
	payload := map[string]interface{}{}

	// Customize payload
	err := generator.CustomizeYandexPayload(payload)

	// Verify no error
	assert.NoError(t, err)

	// Verify payload was customized
	assert.Equal(t, merchant.Name, payload["merchant_name"])
	assert.Equal(t, merchant.Domain, payload["domain"])
}

func TestPaymentGenerator_GeneratePaymentData_DifferentCurrencies(t *testing.T) {
	// Create test data
	testData := yapaytesting.NewTestData()
	merchant := testData.CreateTestMerchant()

	// Create payment generator with logger
	logger := logrus.New()
	generator := NewPaymentGenerator(merchant, logger).(*PaymentGenerator)

	// Test different currencies
	currencies := []string{"RUB", "USD", "EUR"}
	amounts := []int{1000, 100, 50} // Different amounts in kopecks/cents

	for i, currency := range currencies {
		request := &yapay.PaymentRequest{
			Amount:      amounts[i],
			Currency:    currency,
			Description: "Test payment",
			ReturnURL:   "https://example.com/return",
		}

		result, err := generator.GeneratePaymentData(request)
		require.NoError(t, err)
		require.NotNil(t, result)

		// Verify currency is preserved
		assert.Equal(t, currency, result.Currency)
		assert.Equal(t, amounts[i], result.Amount)

		// Verify PaymentData structure
		amountData, exists := result.PaymentData["amount"].(map[string]interface{})
		require.True(t, exists)
		assert.Equal(t, currency, amountData["currency"])

		// Verify amount conversion (kopecks/cents to main currency)
		expectedValue := fmt.Sprintf("%.2f", float64(amounts[i])/100)
		assert.Equal(t, expectedValue, amountData["value"])
	}
}

// Benchmark tests
func BenchmarkHandler_OnPaymentCreated(b *testing.B) {
	// Create test data
	testData := yapaytesting.NewTestData()
	merchant := testData.CreateTestMerchant()
	payment := testData.CreateTestPayment()

	// Create handler
	handler := NewHandler(merchant).(*Handler)

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_ = handler.OnPaymentCreated(payment)
	}
}

// ValidateRequest method was removed as it's not part of PaymentEventHandler interface

func BenchmarkPaymentGenerator_GeneratePaymentData(b *testing.B) {
	// Create test data
	testData := yapaytesting.NewTestData()
	merchant := testData.CreateTestMerchant()
	request := testData.CreateTestPaymentRequest()

	// Create payment generator with logger
	logger := logrus.New()
	generator := NewPaymentGenerator(merchant, logger).(*PaymentGenerator)

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, _ = generator.GeneratePaymentData(request)
	}
}
