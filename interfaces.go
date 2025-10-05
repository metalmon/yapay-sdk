package yapaysdk

import (
	"github.com/sirupsen/logrus"
)

// PaymentRequest represents a payment request (LTS version)
type PaymentRequest struct {
	// Current fields (remain as is)
	Amount      int                    `json:"amount"`
	Currency    string                 `json:"currency"`
	Description string                 `json:"description"`
	ReturnURL   string                 `json:"return_url"`
	Metadata    map[string]interface{} `json:"metadata,omitempty"`

	// New LTS fields (not processed yet - future enhancement)
	Customer     *CustomerInfo       `json:"customer,omitempty"`
	Cart         []*CartItem         `json:"cart,omitempty"`
	Delivery     *DeliveryInfo       `json:"delivery,omitempty"`
	PaymentPrefs *PaymentPreferences `json:"payment_preferences,omitempty"`
}

// Payment represents a payment (LTS version)
type Payment struct {
	// Current fields (remain as is)
	ID          string                 `json:"id"`
	OrderID     string                 `json:"order_id"`
	MerchantID  string                 `json:"merchant_id"` // Merchant ID from Yandex Pay (also serves as client ID)
	Amount      int                    `json:"amount"`
	Currency    string                 `json:"currency"`
	Description string                 `json:"description"`
	Status      string                 `json:"status"`
	ReturnURL   string                 `json:"return_url"`
	PaymentURL  string                 `json:"payment_url,omitempty"`
	Environment string                 `json:"environment,omitempty"` // Environment: "production" or "sandbox"
	Metadata    map[string]interface{} `json:"metadata,omitempty"`
	CreatedAt   string                 `json:"created_at,omitempty"`
	UpdatedAt   string                 `json:"updated_at,omitempty"`

	// Integration data prepared by plugin
	IntegrationData []IntegrationData `json:"integration_data,omitempty"`

	// New LTS fields (not processed yet - future enhancement)
	Cart         *RenderedCart         `json:"cart,omitempty"`
	Extensions   *OrderExtensions      `json:"extensions,omitempty"`
	RedirectUrls *MerchantRedirectUrls `json:"redirectUrls,omitempty"`
	Risk         *MerchantRiskInfo     `json:"risk,omitempty"`
	Customer     *CustomerInfo         `json:"customer,omitempty"`
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
	Integrations  []IntegrationConfig    `json:"integrations,omitempty" yaml:"integrations,omitempty"`
	FieldLabels   FieldLabels            `json:"field_labels,omitempty" yaml:"field_labels,omitempty"`
	Plugin        PluginConfig           `json:"plugin,omitempty" yaml:"plugin,omitempty"`
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
	APIKey         string `json:"api_key,omitempty" yaml:"api_key,omitempty"`
	SandboxMode    bool   `json:"sandbox_mode" yaml:"sandbox_mode"`
	Currency       string `json:"currency" yaml:"currency"`
	APIBaseURL     string `json:"api_base_url,omitempty" yaml:"api_base_url,omitempty"`
	OrdersEndpoint string `json:"orders_endpoint,omitempty" yaml:"orders_endpoint,omitempty"`
	JWKSEndpoint   string `json:"jwks_endpoint,omitempty" yaml:"jwks_endpoint,omitempty"`
	PrivateKeyPath string `json:"private_key_path,omitempty" yaml:"private_key_path,omitempty"`
}

// NotificationConfig represents notification configuration
type NotificationConfig struct {
	Telegram TelegramConfig       `json:"telegram" yaml:"telegram"`
	Email    EmailConfig          `json:"email" yaml:"email"`
	Messages NotificationMessages `json:"messages,omitempty" yaml:"messages,omitempty"`
}

// NotificationMessages represents customizable notification message templates
type NotificationMessages struct {
	// Payment notifications
	PaymentCreatedTitle string `json:"payment_created_title,omitempty" yaml:"payment_created_title,omitempty"`
	PaymentSuccessTitle string `json:"payment_success_title,omitempty" yaml:"payment_success_title,omitempty"`
	PaymentFailedTitle  string `json:"payment_failed_title,omitempty" yaml:"payment_failed_title,omitempty"`
	PaymentDetailsTitle string `json:"payment_details_title,omitempty" yaml:"payment_details_title,omitempty"`

	// Request notifications
	RequestTitle        string            `json:"request_title,omitempty" yaml:"request_title,omitempty"`
	RequestDetailsTitle string            `json:"request_details_title,omitempty" yaml:"request_details_title,omitempty"`
	RequestTypeLabels   map[string]string `json:"request_type_labels,omitempty" yaml:"request_type_labels,omitempty"`
}

// FieldLabels represents field labels for order metadata in notifications
type FieldLabels map[string]string

// PluginConfig represents plugin configuration
type PluginConfig struct {
	Type string `json:"type" yaml:"type"`                     // "builtin", "so", "grpc"
	Path string `json:"path,omitempty" yaml:"path,omitempty"` // Path to plugin file (for so/grpc)
}

// TelegramConfig represents Telegram notification configuration
type TelegramConfig struct {
	Enabled  bool     `json:"enabled" yaml:"enabled"`
	ChatIDs  []string `json:"chat_ids" yaml:"chat_ids"` // Поддержка нескольких chat_id
	BotToken string   `json:"bot_token" yaml:"bot_token"`
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

// PaymentLinkGenerator defines the interface for payment link generation
type PaymentLinkGenerator interface {
	// Payment methods (existing)
	GeneratePaymentData(req *PaymentRequest) (*PaymentGenerationResult, error)
	ValidatePriceFromBackend(req *PaymentRequest) error
	GetPaymentSettings() *PaymentSettings
	CustomizeYandexPayload(payload map[string]interface{}) error

	// Request methods (new - for non-payment requests like consultations, callbacks)
	ProcessRequest(req *RequestData) (*RequestResult, error)
	ValidateRequestData(req *RequestData) error
	GetRequestSettings() *RequestSettings
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

// RequestData represents a non-payment request (consultation, callback, etc.)
type RequestData struct {
	ID          string                 `json:"id"`
	ClientID    string                 `json:"client_id"`
	Type        string                 `json:"type"` // "consultation", "callback", "custom", etc.
	Description string                 `json:"description"`
	Metadata    map[string]interface{} `json:"metadata"`
	Status      string                 `json:"status"` // "pending", "processed", "canceled"
	CreatedAt   string                 `json:"created_at,omitempty"`
	UpdatedAt   string                 `json:"updated_at,omitempty"`

	// Integration data prepared by plugin
	IntegrationData []IntegrationData `json:"integration_data,omitempty"`
}

// RequestResult represents the result of request processing
type RequestResult struct {
	Success  bool                   `json:"success"`
	Message  string                 `json:"message,omitempty"`
	Data     map[string]interface{} `json:"data,omitempty"`
	Metadata map[string]interface{} `json:"metadata,omitempty"`
}

// RequestSettings represents settings for request processing
type RequestSettings struct {
	Enabled    bool                   `json:"enabled"`
	Types      []string               `json:"types"`
	Fields     map[string]interface{} `json:"fields,omitempty"`
	Validation map[string]interface{} `json:"validation,omitempty"`
}

// PaymentEventHandler defines the interface for handling payment events
// This interface allows plugins to implement custom business logic for payment lifecycle events
type PaymentEventHandler interface {
	// OnPaymentCreated is called when a payment is created
	OnPaymentCreated(payment *Payment) error

	// OnPaymentSuccess is called when a payment succeeds
	OnPaymentSuccess(payment *Payment) error

	// OnPaymentFailed is called when a payment fails
	OnPaymentFailed(payment *Payment) error

	// OnPaymentCanceled is called when a payment is canceled
	OnPaymentCanceled(payment *Payment) error

	// OnPaymentPending is called when a payment is pending
	OnPaymentPending(payment *Payment) error
}

// RequestEventHandler defines the interface for handling request events
// This interface allows plugins to implement custom business logic for request lifecycle events
type RequestEventHandler interface {
	// OnRequestCreated is called when a request is created
	OnRequestCreated(req *RequestData) error

	// OnRequestSuccess is called when a request is processed successfully
	OnRequestSuccess(req *RequestData) error

	// OnRequestFailed is called when a request processing fails
	OnRequestFailed(req *RequestData) error

	// OnRequestCanceled is called when a request is canceled
	OnRequestCanceled(req *RequestData) error

	// OnRequestPending is called when a request is pending
	OnRequestPending(req *RequestData) error
}

// NewPaymentGeneratorFunc is the function signature for creating a payment generator
// This function must be exported from the plugin as "NewPaymentGenerator"
type NewPaymentGeneratorFunc func(*Merchant, *logrus.Logger) PaymentLinkGenerator

// NewPaymentEventHandlerFunc is the function signature for creating a payment event handler
// This function must be exported from the plugin as "NewPaymentEventHandler"
type NewPaymentEventHandlerFunc func(*Merchant, *logrus.Logger) PaymentEventHandler

// NewHandlerFunc is the function signature for creating a plugin handler
// This function must be exported from the plugin as "NewHandler"
type NewHandlerFunc func(*Merchant, *logrus.Logger) interface{}

// VersionedPlugin represents a plugin that can report its SDK version
type VersionedPlugin interface {
	// GetSDKVersion returns the SDK version this plugin was built against
	GetSDKVersion() string
}

// IntegrationData represents integration data prepared by plugin
type IntegrationData struct {
	BeforeGenerate bool                   `json:"before_generate"`  // true = ДО генерации, false = ПОСЛЕ
	Type           string                 `json:"type"`             // "crm", "validation", "webhook"
	Payload        map[string]interface{} `json:"payload"`          // Бизнес-данные от плагина
	Result         map[string]interface{} `json:"result,omitempty"` // Результат (заполняет сервер)
}

// TelegramMessage represents an incoming message from Telegram
type TelegramMessage struct {
	MessageID int                    `json:"message_id"`
	UserID    int                    `json:"user_id"`
	Username  string                 `json:"username,omitempty"`
	Text      string                 `json:"text"`
	ReplyTo   *TelegramMessage       `json:"reply_to_message,omitempty"`
	Timestamp string                 `json:"timestamp"`
	Metadata  map[string]interface{} `json:"metadata,omitempty"`
}

// TelegramCallback represents a callback query from Telegram
type TelegramCallback struct {
	ID        string                 `json:"id"`
	UserID    int                    `json:"user_id"`
	Username  string                 `json:"username,omitempty"`
	Data      string                 `json:"data"`
	MessageID int                    `json:"message_id"`
	Timestamp string                 `json:"timestamp"`
	Metadata  map[string]interface{} `json:"metadata,omitempty"`
}

// TelegramResponse represents a response to send back to Telegram
type TelegramResponse struct {
	Text      string                 `json:"text"`
	ReplyToID int                    `json:"reply_to_message_id,omitempty"`
	ParseMode string                 `json:"parse_mode,omitempty"`
	Actions   []TelegramAction       `json:"actions,omitempty"`
	Metadata  map[string]interface{} `json:"metadata,omitempty"`
}

// TelegramAction represents an action to perform
type TelegramAction struct {
	Type string                 `json:"type"` // "send_payment_link", "send_message"
	Data map[string]interface{} `json:"data"`
}

// IntegrationConfig represents integration configuration
type IntegrationConfig struct {
	Name       string                 `json:"name" yaml:"name"`
	Type       string                 `json:"type" yaml:"type"` // "crm", "validation", "webhook"
	Enabled    bool                   `json:"enabled" yaml:"enabled"`
	URL        string                 `json:"url" yaml:"url"`
	Method     string                 `json:"method" yaml:"method"`
	AuthType   string                 `json:"auth_type" yaml:"auth_type"`
	AuthConfig map[string]interface{} `json:"auth_config" yaml:"auth_config"`
	Headers    map[string]string      `json:"headers" yaml:"headers"`
	Timeout    string                 `json:"timeout" yaml:"timeout"`
	Events     []string               `json:"events" yaml:"events"`
	Fields     map[string]interface{} `json:"fields" yaml:"fields"`
}

// TelegramBotProvider defines the interface for handling Telegram bot interactions
type TelegramBotProvider interface {
	// OnTelegramMessage handles incoming messages from Telegram
	OnTelegramMessage(message *TelegramMessage) (*TelegramResponse, error)

	// OnTelegramCallback handles callback queries from Telegram
	OnTelegramCallback(callback *TelegramCallback) (*TelegramResponse, error)
}

// RequestDataGenerator defines the interface for request data generation
type RequestDataGenerator interface {
	ProcessRequest(req *RequestData) (*RequestResult, error)
	ValidateRequestData(req *RequestData) error
	GetRequestSettings() *RequestSettings
}

// ============================================================================
// LTS (Long Term Support) structures for complete Yandex Pay API support
// These structures provide full compatibility with Yandex Pay Merchant API
// ============================================================================

// CustomerInfo represents customer information
type CustomerInfo struct {
	Email string `json:"email,omitempty"`
	Phone string `json:"phone,omitempty"`
	Name  string `json:"name,omitempty"`
}

// CartItem represents a simple cart item
type CartItem struct {
	ProductID   string `json:"product_id"`
	Title       string `json:"title"`
	Description string `json:"description,omitempty"`
	Quantity    int    `json:"quantity"`
	UnitPrice   int    `json:"unit_price"` // In kopecks
}

// DeliveryInfo represents delivery information
type DeliveryInfo struct {
	Method  string `json:"method,omitempty"`  // "pickup", "delivery"
	Address string `json:"address,omitempty"` // Delivery address
	Price   int    `json:"price,omitempty"`   // Delivery price in kopecks
}

// PaymentPreferences represents payment preferences
type PaymentPreferences struct {
	PreferredPaymentMethod string   `json:"preferred_payment_method,omitempty"` // "FULLPAYMENT", "SPLIT"
	AvailableMethods       []string `json:"available_methods,omitempty"`        // ["SPLIT", "CARD"]
	IsPrepayment           bool     `json:"is_prepayment,omitempty"`            // Prepayment flag
}

// RenderedCart represents the complete cart structure from Yandex Pay API
type RenderedCart struct {
	ExternalID string              `json:"externalId,omitempty"`
	Items      []*RenderedCartItem `json:"items"`
	Total      *CartTotal          `json:"total"`
}

// RenderedCartItem represents a complete cart item with all features
type RenderedCartItem struct {
	Description         string            `json:"description"`
	DiscountedUnitPrice string            `json:"discountedUnitPrice"`
	Features            *CartItemFeatures `json:"features,omitempty"`
	PointsAmount        string            `json:"pointsAmount,omitempty"`
	ProductID           string            `json:"productId"`
	Quantity            *ItemQuantity     `json:"quantity"`
	Receipt             *ItemReceipt      `json:"receipt,omitempty"`
	SKUID               string            `json:"skuId,omitempty"`
	Subtotal            string            `json:"subtotal"`
	Title               string            `json:"title"`
	Total               string            `json:"total"`
	UnitPrice           string            `json:"unitPrice"`
}

// CartTotal represents cart totals
type CartTotal struct {
	Amount       string `json:"amount"`
	PointsAmount string `json:"pointsAmount,omitempty"`
}

// CartItemFeatures represents cart item features
type CartItemFeatures struct {
	PointsDisabled bool   `json:"pointsDisabled,omitempty"`
	TariffModifier string `json:"tariffModifier,omitempty"` // "VERY_LOW", "LOW", "MEDIUM", "HIGH", "VERY_HIGH"
}

// ItemQuantity represents item quantity information
type ItemQuantity struct {
	Count     string `json:"count"`
	Available string `json:"available,omitempty"`
}

// ItemReceipt represents fiscal receipt information
type ItemReceipt struct {
	Tax                int           `json:"tax"`
	Agent              *Agent        `json:"agent,omitempty"`
	Excise             string        `json:"excise,omitempty"`
	MarkQuantity       *MarkQuantity `json:"markQuantity,omitempty"`
	Measure            int           `json:"measure,omitempty"`
	PaymentMethodType  int           `json:"paymentMethodType,omitempty"`
	PaymentSubjectType int           `json:"paymentSubjectType,omitempty"`
	ProductCode        string        `json:"productCode,omitempty"`
	Supplier           *Supplier     `json:"supplier,omitempty"`
	Title              string        `json:"title"`
}

// Agent represents agent information
type Agent struct {
	AgentType        int               `json:"agentType"`
	Operation        string            `json:"operation,omitempty"`
	PaymentsOperator *PaymentsOperator `json:"paymentsOperator,omitempty"`
	Phones           []string          `json:"phones,omitempty"`
	TransferOperator *TransferOperator `json:"transferOperator,omitempty"`
}

// MarkQuantity represents mark quantity information
type MarkQuantity struct {
	Denominator int `json:"denominator"`
	Numerator   int `json:"numerator"`
}

// Supplier represents supplier information
type Supplier struct {
	INN    string   `json:"inn,omitempty"`
	Name   string   `json:"name,omitempty"`
	Phones []string `json:"phones,omitempty"`
}

// PaymentsOperator represents payments operator information
type PaymentsOperator struct {
	Phones []string `json:"phones,omitempty"`
}

// TransferOperator represents transfer operator information
type TransferOperator struct {
	Address string   `json:"address,omitempty"`
	INN     string   `json:"inn,omitempty"`
	Name    string   `json:"name,omitempty"`
	Phones  []string `json:"phones,omitempty"`
}

// OrderExtensions represents order extensions
type OrderExtensions struct {
	BillingReport *BillingReport `json:"billingReport,omitempty"`
	PaymentData   *PaymentData   `json:"paymentData,omitempty"`
	QRData        *QRData        `json:"qrData,omitempty"`
	SMSOffer      *SMSOffer      `json:"smsOffer,omitempty"`
}

// BillingReport represents billing report information
type BillingReport struct {
	BranchID  *string `json:"branchId,omitempty"`
	ManagerID *string `json:"managerId,omitempty"`
}

// PaymentData represents payment data
type PaymentData struct {
	SaleToken string `json:"saleToken,omitempty"`
}

// QRData represents QR code data
type QRData struct {
	Token string `json:"token,omitempty"`
}

// SMSOffer represents SMS offer information
type SMSOffer struct {
	Phone string `json:"phone,omitempty"`
}

// MerchantRedirectUrls represents merchant redirect URLs
type MerchantRedirectUrls struct {
	OnAbort   string `json:"onAbort,omitempty"`
	OnError   string `json:"onError,omitempty"`
	OnSuccess string `json:"onSuccess,omitempty"`
}

// MerchantRiskInfo represents merchant risk information
type MerchantRiskInfo struct {
	BillingPhone                   string                 `json:"billingPhone,omitempty"`
	CustomerAggregates             *CustomerAggregates    `json:"customerAggregates,omitempty"`
	DeviceID                       string                 `json:"deviceId,omitempty"`
	IsExpressShipping              bool                   `json:"isExpressShipping,omitempty"`
	MerchantMCC                    string                 `json:"merchantMcc,omitempty"`
	MerchantName                   string                 `json:"merchantName,omitempty"`
	MerchantOfflinePosLegalAddress string                 `json:"merchantOfflinePosLegalAddress,omitempty"`
	MerchantTaxRefNumber           string                 `json:"merchantTaxRefNumber,omitempty"`
	PeriodCheckAggregates          *PeriodCheckAggregates `json:"periodCheckAggregates,omitempty"`
	QRType                         string                 `json:"qrType,omitempty"`
	QRCID                          string                 `json:"qrcId,omitempty"`
}

// CustomerAggregates represents customer aggregates for risk analysis
type CustomerAggregates struct {
	AmountFirstSuccessfulOrder            string `json:"amountFirstSuccessfulOrder,omitempty"`
	AmountLatestSuccessfulOrder           string `json:"amountLatestSuccessfulOrder,omitempty"`
	Cookie                                string `json:"cookie,omitempty"`
	DaysSinceLastPasswordReset            int    `json:"daysSinceLastPasswordReset,omitempty"`
	FailedLoginAttemptsOneDay             int    `json:"failedLoginAttemptsOneDay,omitempty"`
	FailedLoginAttemptsSevenDays          int    `json:"failedLoginAttemptsSevenDays,omitempty"`
	FirstSuccessfulOrderDate              string `json:"firstSuccessfulOrderDate,omitempty"`
	HistoricalCookieLogin                 bool   `json:"historicalCookieLogin,omitempty"`
	HistoricalDeviceLogin                 bool   `json:"historicalDeviceLogin,omitempty"`
	LastPasswordResetDate                 string `json:"lastPasswordResetDate,omitempty"`
	LatestSuccessfulOrderLastYearDate     string `json:"latestSuccessfulOrderLastYearDate,omitempty"`
	PreviousSuccessfulOrdersAtSameAddress bool   `json:"previousSuccessfulOrdersAtSameAddress,omitempty"`
	RedemptionRateLastHalfYear            string `json:"redemptionRateLastHalfYear,omitempty"`
	RegistrationDate                      string `json:"registrationDate,omitempty"`
}

// PeriodCheckAggregates represents period check aggregates for risk analysis
type PeriodCheckAggregates struct {
	SuccessfulOrdersCountNineMonths         int    `json:"successfulOrdersCountNineMonths,omitempty"`
	SuccessfulOrdersCountOneMonth           int    `json:"successfulOrdersCountOneMonth,omitempty"`
	SuccessfulOrdersCountSixMonths          int    `json:"successfulOrdersCountSixMonths,omitempty"`
	SuccessfulOrdersCountThreeMonths        int    `json:"successfulOrdersCountThreeMonths,omitempty"`
	SuccessfulOrdersCountTwelveMonths       int    `json:"successfulOrdersCountTwelveMonths,omitempty"`
	TotalAmountSuccessfulOrdersNineMonths   string `json:"totalAmountSuccessfulOrdersNineMonths,omitempty"`
	TotalAmountSuccessfulOrdersOneMonth     string `json:"totalAmountSuccessfulOrdersOneMonth,omitempty"`
	TotalAmountSuccessfulOrdersSixMonths    string `json:"totalAmountSuccessfulOrdersSixMonths,omitempty"`
	TotalAmountSuccessfulOrdersThreeMonths  string `json:"totalAmountSuccessfulOrdersThreeMonths,omitempty"`
	TotalAmountSuccessfulOrdersTwelveMonths string `json:"totalAmountSuccessfulOrdersTwelveMonths,omitempty"`
}
