module simple-plugin

go 1.24.0

toolchain go1.24.7

require (
	github.com/metalmon/yapay-sdk v1.0.11
	github.com/sirupsen/logrus v1.9.3
	github.com/stretchr/testify v1.11.1
)

// Replace директива для использования локальной версии SDK
replace github.com/metalmon/yapay-sdk => ../../

// Replace директива для синхронизации версии golang.org/x/sys
replace golang.org/x/sys => golang.org/x/sys v0.36.0

require (
	github.com/davecgh/go-spew v1.1.1 // indirect
	github.com/pmezard/go-difflib v1.0.0 // indirect
	golang.org/x/sys v0.36.0 // indirect
	gopkg.in/yaml.v3 v3.0.1 // indirect
)
