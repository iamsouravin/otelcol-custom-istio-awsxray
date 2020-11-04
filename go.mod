module github.com/iamsouravin/otelcol-custom-istio-awsxray

go 1.15

replace (
	github.com/open-telemetry/opentelemetry-collector-contrib/exporter/awsxrayexporter => /src/dependencies/awsxrayexporter
	github.com/open-telemetry/opentelemetry-collector-contrib/internal/awsxray => github.com/open-telemetry/opentelemetry-collector-contrib/internal/awsxray v0.13.1
)

require (
	github.com/open-telemetry/opentelemetry-collector-contrib/exporter/awsxrayexporter v0.13.1
	go.opentelemetry.io/collector v0.13.1-0.20201027215027-6ae66159741d
)
