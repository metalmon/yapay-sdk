module plugin-debug

go 1.22

toolchain go1.22.0

require (
	github.com/metalmon/yapay-sdk v1.0.6
	gopkg.in/yaml.v3 v3.0.1
)

require (
	github.com/sirupsen/logrus v1.9.3 // indirect
	golang.org/x/sys v0.15.0 // indirect
)

replace github.com/metalmon/yapay-sdk => ../..
