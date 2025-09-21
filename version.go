package yapay

// SDKVersion represents the current SDK version
const (
	SDKVersion       = "1.0.7"
	SDKVersionString = "v" + SDKVersion
)

// GetSDKVersion returns the current SDK version as a string (e.g., "1.0.7")
// This is the recommended way for plugins to report their SDK version
func GetSDKVersion() string {
	return SDKVersion
}
