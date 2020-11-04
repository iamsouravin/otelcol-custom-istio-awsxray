package main

import (
	"errors"
	"fmt"
	"log"
	"os"
	"syscall"

	"github.com/iamsouravin/otelcol-custom-istio-awsxray/version"
	"go.opentelemetry.io/collector/component"
	"go.opentelemetry.io/collector/service"
)

func main() {
	factories, err := components()
	if err != nil {
		log.Fatalf("failed to build components: %v", err)
	}

	info := &component.ApplicationStartInfo{
		ExeName:  "otelcol-custom-istio-awsxray",
		LongName: "OpenTelemetry Collector Custom Distribution",
		Version:  version.RELEASE,
		GitHash:  version.COMMIT,
	}

	err = run(info, factories)
	if err != nil {
		log.Fatal(err)
	}
}

func run(info *component.ApplicationStartInfo, factories *component.Factories) error {
	app, err := service.New(service.Parameters{ApplicationStartInfo: *info, Factories: *factories})
	if err != nil {
		return fmt.Errorf("failed to construct the application: %w", err)
	}

	err = wrapRunError(app.Run())
	return err
}

func wrapRunError(err error) error {
	if err == nil {
		return nil
	}
	return skipIgnorableError(err)
}

func skipIgnorableError(err error) error {
	// Implementation concept from logging_exporter.go:loggerSync(*zap.Logger)
	// Exporters may sync logger on shutdown
	// Currently Sync() on stdout and stderr return errors on Linux and macOS,
	// respectively:
	//
	// - sync /dev/stdout: invalid argument
	// - sync /dev/stdout: inappropriate ioctl for device
	//
	// Since these are not actionable ignore them.
	var pathError *os.PathError
	if errors.As(err, &pathError) {
		pathError = unwrapToPathError(err)

		switch pathError.Err {
		case syscall.EINVAL, syscall.ENOTSUP, syscall.ENOTTY:
			// Ignore the error.
			return nil
		}
	}

	return fmt.Errorf("application run finished with error: %w", err)
}

func unwrapToPathError(err error) *os.PathError {
	var pathError *os.PathError
	var wrappedErr error
	var ok bool
	for pathError, ok, wrappedErr = unwrap(err); !ok; pathError, ok, wrappedErr = unwrap(wrappedErr) {
		// Unwrap until we get to PathError
	}
	return pathError
}

func unwrap(err error) (*os.PathError, bool, error) {
	wrappedErr := errors.Unwrap(err)
	pathError, ok := wrappedErr.(*os.PathError)

	return pathError, ok, wrappedErr
}
