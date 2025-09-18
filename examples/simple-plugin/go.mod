module simple-plugin

go 1.21

require (
	github.com/metalmon/yapay-sdk v1.0.6
	github.com/sirupsen/logrus v1.9.3
	github.com/stretchr/testify v1.11.1
)

require (
	github.com/davecgh/go-spew v1.1.1 // indirect
	github.com/pmezard/go-difflib v1.0.0 // indirect
	golang.org/x/sys v0.13.0 // indirect
	gopkg.in/yaml.v3 v3.0.1 // indirect
)

replace github.com/metalmon/yapay-sdk => ../..
