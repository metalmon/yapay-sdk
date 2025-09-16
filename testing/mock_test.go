package testing

import (
	"testing"

	"github.com/metalmon/yapay-sdk"
	"github.com/stretchr/testify/assert"
)

// TestMockClientHandlerImplementsInterface tests that MockClientHandler implements ClientHandler interface
func TestMockClientHandlerImplementsInterface(t *testing.T) {
	// This test will fail at compile time if MockClientHandler doesn't implement ClientHandler
	var handler yapay.ClientHandler = NewMockClientHandler()
	assert.NotNil(t, handler)
}

// TestMockPaymentGeneratorImplementsInterface tests that MockPaymentGenerator implements PaymentLinkGenerator interface
func TestMockPaymentGeneratorImplementsInterface(t *testing.T) {
	// This test will fail at compile time if MockPaymentGenerator doesn't implement PaymentLinkGenerator
	var generator yapay.PaymentLinkGenerator = NewMockPaymentGenerator()
	assert.NotNil(t, generator)
}

// TestMockClientHandlerMethods tests that all required methods work correctly
func TestMockClientHandlerMethods(t *testing.T) {
	mock := NewMockClientHandler()
	testData := NewTestData()
	merchant := testData.CreateTestMerchant()
	payment := testData.CreateTestPayment()
	request := testData.CreateTestPaymentRequest()

	// Set merchant
	mock.SetMerchant(merchant)

	// Test all methods
	assert.NoError(t, mock.HandlePaymentCreated(payment))
	assert.NoError(t, mock.HandlePaymentSuccess(payment))
	assert.NoError(t, mock.HandlePaymentFailed(payment))
	assert.NoError(t, mock.HandlePaymentCanceled(payment))
	assert.NoError(t, mock.ValidateRequest(request))

	// Test getters
	assert.Equal(t, merchant, mock.GetMerchantConfig())
	assert.Equal(t, merchant.Yandex.MerchantID, mock.GetMerchantID())
	assert.Equal(t, merchant.Name, mock.GetMerchantName())

	// Test payment generator
	assert.Nil(t, mock.GetPaymentLinkGenerator())
	mock.SetPaymentLinkGenerator(NewMockPaymentGenerator())
	assert.NotNil(t, mock.GetPaymentLinkGenerator())

	// Test call counts
	counts := mock.GetCallCounts()
	assert.Equal(t, 1, counts["HandlePaymentCreated"])
	assert.Equal(t, 1, counts["HandlePaymentSuccess"])
	assert.Equal(t, 1, counts["HandlePaymentFailed"])
	assert.Equal(t, 1, counts["HandlePaymentCanceled"])
	assert.Equal(t, 1, counts["ValidateRequest"])
}

// TestMockPaymentGeneratorMethods tests that all required methods work correctly
func TestMockPaymentGeneratorMethods(t *testing.T) {
	mock := NewMockPaymentGenerator()
	testData := NewTestData()
	request := testData.CreateTestPaymentRequest()
	result := testData.CreateTestPaymentGenerationResult()

	// Set test data
	mock.SetGeneratePaymentDataResult(result, nil)
	mock.SetValidatePriceError(nil)
	mock.SetCustomizePayloadError(nil)

	// Test all methods
	genResult, err := mock.GeneratePaymentData(request)
	assert.NoError(t, err)
	assert.Equal(t, result, genResult)

	assert.NoError(t, mock.ValidatePriceFromBackend(request))

	settings := mock.GetPaymentSettings()
	assert.NotNil(t, settings)
	assert.Equal(t, "RUB", settings.Currency)
	assert.True(t, settings.SandboxMode)

	payload := map[string]interface{}{"test": "value"}
	assert.NoError(t, mock.CustomizeYandexPayload(payload))

	// Test call counts
	counts := mock.GetCallCounts()
	assert.Equal(t, 1, counts["GeneratePaymentData"])
	assert.Equal(t, 1, counts["ValidatePriceFromBackend"])
	assert.Equal(t, 1, counts["GetPaymentSettings"])
	assert.Equal(t, 1, counts["CustomizeYandexPayload"])
}
