module plugin-debug

go 1.21

require (
	github.com/metalmon/yapay-sdk v1.0.3
	gopkg.in/yaml.v3 v3.0.1
)

require (
	github.com/sirupsen/logrus v1.9.3 // indirect
	golang.org/x/sys v0.13.0 // indirect
)

replace github.com/metalmon/yapay-sdk => ../..
