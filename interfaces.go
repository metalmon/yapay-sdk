package yapay

import (
	"github.com/sirupsen/logrus"
)

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
	MerchantID  string                 `json:"merchant_id"` // Merchant ID from Yandex Pay (also serves as client ID)
	Amount      int                    `json:"amount"`
	Currency    string                 `json:"currency"`
	Description string                 `json:"description"`
	Status      string                 `json:"status"`
	ReturnURL   string                 `json:"return_url"`
	PaymentURL  string                 `json:"payment_url,omitempty"`
	Metadata    map[string]interface{} `json:"metadata,omitempty"`
	CreatedAt   string                 `json:"created_at,omitempty"`
	UpdatedAt   string                 `json:"updated_at,omitempty"`
}

// Merchant represents a merchant configuration
type Merchant struct {
	ID            string                 `json:"id" yaml:"id"`
	Name          string                 `json:"name" yaml:"name"`
	Description   string                 `json:"description" yaml:"description"`
	Domain        string                 `json:"domain" yaml:"domain"`
	Enabled       bool                   `json:"enabled" yaml:"enabled"`
	SandboxMode   bool                   `json:"sandbox_mode" yaml:"sandbox_mode"`
	Security      SecurityConfig         `json:"security" yaml:"security"`
	Metadata      map[string]interface{} `json:"metadata,omitempty" yaml:"metadata,omitempty"`
	Yandex        YandexConfig           `json:"yandex" yaml:"yandex"`
	Notifications NotificationConfig     `json:"notifications" yaml:"notifications"`
	FieldLabels   FieldLabels            `json:"field_labels,omitempty" yaml:"field_labels,omitempty"`
}

// SecurityConfig represents per-merchant security configuration
type SecurityConfig struct {
	// RequestEnforcement controls request validation policy: strict | origin | monitor
	RequestEnforcement string     `json:"request_enforcement" yaml:"request_enforcement"`
	RateLimit          int        `json:"rate_limit" yaml:"rate_limit"`
	CORS               CORSConfig `json:"cors" yaml:"cors"`
}

// CORSConfig represents CORS-related settings for a merchant
type CORSConfig struct {
	Origins []string `json:"origins" yaml:"origins"`
}

// YandexConfig represents Yandex API configuration
type YandexConfig struct {
	MerchantID     string `json:"merchant_id" yaml:"merchant_id"`
	SecretKey      string `json:"secret_key" yaml:"secret_key"`
	SandboxMode    bool   `json:"sandbox_mode" yaml:"sandbox_mode"`
	Currency       string `json:"currency" yaml:"currency"`
	APIBaseURL     string `json:"api_base_url,omitempty" yaml:"api_base_url,omitempty"`
	OrdersEndpoint string `json:"orders_endpoint,omitempty" yaml:"orders_endpoint,omitempty"`
	JWKSEndpoint   string `json:"jwks_endpoint,omitempty" yaml:"jwks_endpoint,omitempty"`
	PrivateKeyPath string `json:"private_key_path,omitempty" yaml:"private_key_path,omitempty"`
}

// NotificationConfig represents notification configuration
type NotificationConfig struct {
	Telegram TelegramConfig `json:"telegram" yaml:"telegram"`
	Email    EmailConfig    `json:"email" yaml:"email"`
}

// FieldLabels represents field labels for order metadata in notifications
type FieldLabels map[string]string

// TelegramConfig represents Telegram notification configuration
type TelegramConfig struct {
	Enabled  bool   `json:"enabled" yaml:"enabled"`
	ChatID   string `json:"chat_id" yaml:"chat_id"`
	BotToken string `json:"bot_token" yaml:"bot_token"`
}

// EmailConfig represents email notification configuration
type EmailConfig struct {
	Enabled  bool   `json:"enabled" yaml:"enabled"`
	SMTPHost string `json:"smtp_host" yaml:"smtp_host"`
	SMTPPort int    `json:"smtp_port" yaml:"smtp_port"`
	Username string `json:"username" yaml:"username"`
	Password string `json:"password" yaml:"password"`
	From     string `json:"from" yaml:"from"`
}

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

// NewHandlerFunc is the function signature for creating a new handler
// This function must be exported from the plugin as "NewHandler"
type NewHandlerFunc func(*Merchant) ClientHandler

// NewPaymentGeneratorFunc is the function signature for creating a payment generator
// This function must be exported from the plugin as "NewPaymentGenerator"
type NewPaymentGeneratorFunc func(*Merchant, *logrus.Logger) PaymentLinkGenerator

// PaymentWebhook represents a webhook from Yandex Payment API
// Based on https://pay.yandex.ru/docs/ru/custom/backend/merchant-api/webhook
type PaymentWebhook struct {
	Event        string                   `json:"event" yaml:"event"`
	EventTime    string                   `json:"eventTime" yaml:"eventTime"`
	MerchantID   string                   `json:"merchantId" yaml:"merchantId"`
	Operation    *OperationWebhookData    `json:"operation,omitempty" yaml:"operation,omitempty"`
	Order        *OrderWebhookData        `json:"order,omitempty" yaml:"order,omitempty"`
	Subscription *SubscriptionWebhookData `json:"subscription,omitempty" yaml:"subscription,omitempty"`
}

// OperationWebhookData represents operation information in webhook payload
type OperationWebhookData struct {
	OperationID         string `json:"operationId" yaml:"operationId"`
	OperationType       string `json:"operationType" yaml:"operationType"`
	OrderID             string `json:"orderId" yaml:"orderId"`
	Status              string `json:"status" yaml:"status"`
	ExternalOperationID string `json:"externalOperationId,omitempty" yaml:"externalOperationId,omitempty"`
}

// OrderWebhookData represents order information in webhook payload
type OrderWebhookData struct {
	OrderID        string `json:"orderId" yaml:"orderId"`
	CartUpdated    bool   `json:"cartUpdated" yaml:"cartUpdated"`
	DeliveryStatus string `json:"deliveryStatus,omitempty" yaml:"deliveryStatus,omitempty"`
	PaymentStatus  string `json:"paymentStatus" yaml:"paymentStatus"`
}

// SubscriptionWebhookData represents subscription information in webhook payload
type SubscriptionWebhookData struct {
	CustomerSubscriptionID string `json:"customerSubscriptionId" yaml:"customerSubscriptionId"`
	NextWriteOff           string `json:"nextWriteOff,omitempty" yaml:"nextWriteOff,omitempty"`
	Status                 string `json:"status" yaml:"status"`
	SubscriptionPlanID     string `json:"subscriptionPlanId" yaml:"subscriptionPlanId"`
}

// NotificationRequest represents a request to send a notification
type NotificationRequest struct {
	Type      NotificationType       `json:"type" yaml:"type"`
	ClientID  string                 `json:"client_id" yaml:"client_id"`
	PaymentID string                 `json:"payment_id,omitempty" yaml:"payment_id,omitempty"`
	Message   string                 `json:"message" yaml:"message"`
	Data      map[string]interface{} `json:"data,omitempty" yaml:"data,omitempty"`
}

// NotificationType represents the type of notification
type NotificationType string

const (
	NotificationTypePaymentCreated NotificationType = "payment_created"
	NotificationTypePaymentSuccess NotificationType = "payment_success"
	NotificationTypePaymentFailed  NotificationType = "payment_failed"
	NotificationTypeSystemError    NotificationType = "system_error"
)
