package yapay

import (
	"github.com/sirupsen/logrus"
)

// ClientHandler defines the interface that all client handlers must implement
type ClientHandler interface {
	// Payment lifecycle methods
	HandlePaymentCreated(payment *Payment) error
	HandlePaymentSuccess(payment *Payment) error
	HandlePaymentFailed(payment *Payment) error
	HandlePaymentCanceled(payment *Payment) error

	// Request validation
	ValidateRequest(req *PaymentRequest) error

	// Configuration and metadata
	GetMerchantConfig() *Merchant
	GetMerchantID() string
	GetMerchantName() string

	// Payment link generator
	GetPaymentLinkGenerator() interface{}
	SetPaymentLinkGenerator(generator interface{})
}

// PaymentLinkGenerator defines the interface for payment link generation
type PaymentLinkGenerator interface {
	GeneratePaymentData(req *PaymentRequest) (*PaymentGenerationResult, error)
	ValidatePriceFromBackend(req *PaymentRequest) error
	GetPaymentSettings() *PaymentSettings
	CustomizeYandexPayload(payload map[string]interface{}) error
}

// PaymentGenerationResult represents the result of payment data generation
type PaymentGenerationResult struct {
	PaymentData map[string]interface{} `json:"payment_data"`
	OrderID     string                 `json:"order_id"`
	Amount      int                    `json:"amount"`
	Currency    string                 `json:"currency"`
	Description string                 `json:"description"`
	ReturnURL   string                 `json:"return_url"`
	Metadata    map[string]interface{} `json:"metadata,omitempty"`
}

// PaymentSettings represents payment settings for Yandex Pay
type PaymentSettings struct {
	Currency           string                 `json:"currency"`
	SandboxMode        bool                   `json:"sandbox_mode"`
	AutoConfirmTimeout int                    `json:"auto_confirm_timeout"`
	CustomFields       map[string]interface{} `json:"custom_fields,omitempty"`
}

// PaymentRequest represents a payment request
type PaymentRequest struct {
	Amount      int                    `json:"amount"`
	Currency    string                 `json:"currency"`
	Description string                 `json:"description"`
	ReturnURL   string                 `json:"return_url"`
	Metadata    map[string]interface{} `json:"metadata,omitempty"`
}

// Payment represents a payment
type Payment struct {
	ID          string                 `json:"id"`
	OrderID     string                 `json:"order_id"`
	Amount      int                    `json:"amount"`
	Currency    string                 `json:"currency"`
	Description string                 `json:"description"`
	Status      string                 `json:"status"`
	ReturnURL   string                 `json:"return_url"`
	Metadata    map[string]interface{} `json:"metadata,omitempty"`
	CreatedAt   string                 `json:"created_at,omitempty"`
	UpdatedAt   string                 `json:"updated_at,omitempty"`
}

// Merchant represents a merchant configuration
type Merchant struct {
	ID            string                 `json:"id"`
	Name          string                 `json:"name"`
	Description   string                 `json:"description"`
	Domain        string                 `json:"domain"`
	Enabled       bool                   `json:"enabled"`
	SandboxMode   bool                   `json:"sandbox_mode"`
	CORSOrigins   []string               `json:"cors_origins"`
	RateLimit     int                    `json:"rate_limit"`
	Metadata      map[string]interface{} `json:"metadata,omitempty"`
	Yandex        YandexConfig           `json:"yandex"`
	Notifications NotificationConfig     `json:"notifications"`
	FieldLabels   FieldLabels            `json:"field_labels,omitempty"`
}

// YandexConfig represents Yandex API configuration
type YandexConfig struct {
	MerchantID     string `json:"merchant_id"`
	SecretKey      string `json:"secret_key"`
	SandboxMode    bool   `json:"sandbox_mode"`
	Currency       string `json:"currency"`
	APIBaseURL     string `json:"api_base_url,omitempty"`
	OrdersEndpoint string `json:"orders_endpoint,omitempty"`
	JWKSEndpoint   string `json:"jwks_endpoint,omitempty"`
	PrivateKeyPath string `json:"private_key_path,omitempty"`
}

// NotificationConfig represents notification configuration
type NotificationConfig struct {
	Telegram TelegramConfig `json:"telegram"`
	Email    EmailConfig    `json:"email"`
}

// FieldLabels represents field labels for order metadata in notifications
type FieldLabels map[string]string

// TelegramConfig represents Telegram notification configuration
type TelegramConfig struct {
	Enabled  bool   `json:"enabled"`
	ChatID   string `json:"chat_id"`
	BotToken string `json:"bot_token"`
}

// EmailConfig represents email notification configuration
type EmailConfig struct {
	Enabled  bool   `json:"enabled"`
	SMTPHost string `json:"smtp_host"`
	SMTPPort int    `json:"smtp_port"`
	Username string `json:"username"`
	Password string `json:"password"`
	From     string `json:"from"`
}

// NewHandlerFunc is the function signature for creating a new handler
// This function must be exported from the plugin as "NewHandler"
type NewHandlerFunc func(*Merchant) ClientHandler

// NewPaymentGeneratorFunc is the function signature for creating a payment generator
// This function must be exported from the plugin as "NewPaymentGenerator"
type NewPaymentGeneratorFunc func(*Merchant, *logrus.Logger) PaymentLinkGenerator
