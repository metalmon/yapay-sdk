module plugin-debug

go 1.24.0

toolchain go1.24.7

require (
	github.com/metalmon/yapay-sdk v1.0.11
	gopkg.in/yaml.v3 v3.0.1
)

// Replace директива для использования локальной версии SDK
replace github.com/metalmon/yapay-sdk => ../../

// Replace директива для синхронизации версии golang.org/x/sys
replace golang.org/x/sys => golang.org/x/sys v0.36.0

require (
	github.com/sirupsen/logrus v1.9.3 // indirect
	golang.org/x/sys v0.36.0 // indirect
)
