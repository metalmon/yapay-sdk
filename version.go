package yapay

// SDKVersion represents the current SDK version
const (
	SDKVersion       = "1.0.6"
	SDKVersionString = "v" + SDKVersion
)

// GetSDKVersionString returns the current SDK version as a string (e.g., "v1.0.6")
// This is the recommended way for plugins to report their SDK version
func GetSDKVersionString() string {
	return SDKVersionString
}
