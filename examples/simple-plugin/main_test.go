package main

import (
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

	// Verify handler implements interface
	var _ yapay.ClientHandler = handler

	// Verify handler properties
	assert.Equal(t, merchant, handler.GetMerchantConfig())
	assert.Equal(t, merchant.Yandex.MerchantID, handler.GetMerchantID())
	assert.Equal(t, merchant.Name, handler.GetMerchantName())
}

func TestHandler_HandlePaymentCreated(t *testing.T) {
	// Create test data
	testData := yapaytesting.NewTestData()
	merchant := testData.CreateTestMerchant()
	payment := testData.CreateTestPayment()

	// Create handler
	handler := NewHandler(merchant).(*Handler)

	// Handle payment created
	err := handler.HandlePaymentCreated(payment)

	// Verify no error
	assert.NoError(t, err)

	// Verify payment was processed (in real implementation, you might check logs, database, etc.)
	assert.NotNil(t, handler.merchant)
	assert.NotNil(t, handler.logger)
}

func TestHandler_HandlePaymentSuccess(t *testing.T) {
	// Create test data
	testData := yapaytesting.NewTestData()
	merchant := testData.CreateTestMerchant()
	payment := testData.CreateTestPayment()
	payment.Status = "success"

	// Create handler
	handler := NewHandler(merchant).(*Handler)

	// Handle payment success
	err := handler.HandlePaymentSuccess(payment)

	// Verify no error
	assert.NoError(t, err)
}

func TestHandler_HandlePaymentFailed(t *testing.T) {
	// Create test data
	testData := yapaytesting.NewTestData()
	merchant := testData.CreateTestMerchant()
	payment := testData.CreateTestPayment()
	payment.Status = "failed"

	// Create handler
	handler := NewHandler(merchant).(*Handler)

	// Handle payment failed
	err := handler.HandlePaymentFailed(payment)

	// Verify no error
	assert.NoError(t, err)
}

func TestHandler_HandlePaymentCanceled(t *testing.T) {
	// Create test data
	testData := yapaytesting.NewTestData()
	merchant := testData.CreateTestMerchant()
	payment := testData.CreateTestPayment()
	payment.Status = "canceled"

	// Create handler
	handler := NewHandler(merchant).(*Handler)

	// Handle payment canceled
	err := handler.HandlePaymentCanceled(payment)

	// Verify no error
	assert.NoError(t, err)
}

func TestHandler_ValidateRequest(t *testing.T) {
	testCases := []struct {
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
			errorMessage:  "amount must be positive",
		},
		{
			name: "zero amount",
			request: &yapay.PaymentRequest{
				Amount:      0,
				Description: "Invalid payment",
				ReturnURL:   "https://example.com/return",
			},
			expectedError: true,
			errorMessage:  "amount must be positive",
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
		{
			name: "empty return URL",
			request: &yapay.PaymentRequest{
				Amount:      1000,
				Description: "Valid payment",
				ReturnURL:   "",
			},
			expectedError: true,
			errorMessage:  "return URL is required",
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
}

func TestHandler_GetPaymentLinkGenerator(t *testing.T) {
	// Create test merchant
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

	// Verify order ID format
	assert.Contains(t, result.OrderID, "order_")
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
	assert.Equal(t, "RUB", settings.Currency)
	assert.Equal(t, merchant.Yandex.SandboxMode, settings.SandboxMode)
	assert.Equal(t, 30, settings.AutoConfirmTimeout)
	assert.NotNil(t, settings.CustomFields)
	assert.Equal(t, merchant.Name, settings.CustomFields["merchant_name"])
	assert.Equal(t, merchant.Domain, settings.CustomFields["domain"])
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
		"amount": 1000,
	}

	// Customize payload
	err := generator.CustomizeYandexPayload(payload)

	// Verify no error
	assert.NoError(t, err)

	// Verify payload was customized
	assert.Equal(t, merchant.Name, payload["merchant_name"])
	assert.Equal(t, merchant.Domain, payload["domain"])
}

// Benchmark tests
func BenchmarkHandler_HandlePaymentCreated(b *testing.B) {
	// Create test data
	testData := yapaytesting.NewTestData()
	merchant := testData.CreateTestMerchant()
	payment := testData.CreateTestPayment()

	// Create handler
	handler := NewHandler(merchant).(*Handler)

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_ = handler.HandlePaymentCreated(payment)
	}
}

func BenchmarkHandler_ValidateRequest(b *testing.B) {
	// Create test data
	testData := yapaytesting.NewTestData()
	merchant := testData.CreateTestMerchant()
	request := testData.CreateTestPaymentRequest()

	// Create handler
	handler := NewHandler(merchant).(*Handler)

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_ = handler.ValidateRequest(request)
	}
}

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
