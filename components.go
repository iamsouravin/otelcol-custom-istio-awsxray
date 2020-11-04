package main

import (
	"go.opentelemetry.io/collector/component"
	"go.opentelemetry.io/collector/component/componenterror"
	"go.opentelemetry.io/collector/service/defaultcomponents"

	// exporters
	awsxrayexporter "github.com/open-telemetry/opentelemetry-collector-contrib/exporter/awsxrayexporter"
)

func components() (*component.Factories, error) {
	var errs []error
	factories, err := defaultcomponents.Components()
	if err != nil {
		return &component.Factories{}, err
	}

	addReceivers(&factories, errs)

	addProcessors(&factories, errs)

	addExporters(&factories, errs)

	return &factories, componenterror.CombineErrors(errs)
}

func addReceivers(factories *component.Factories, errs []error) {
	receivers := []component.ReceiverFactory{}
	for _, rec := range factories.Receivers {
		receivers = append(receivers, rec)
	}
	var err error
	factories.Receivers, err = component.MakeReceiverFactoryMap(receivers...)
	if err != nil {
		errs = append(errs, err)
	}
}

func addProcessors(factories *component.Factories, errs []error) {
	processors := []component.ProcessorFactory{}
	for _, pr := range factories.Processors {
		processors = append(processors, pr)
	}
	var err error
	factories.Processors, err = component.MakeProcessorFactoryMap(processors...)
	if err != nil {
		errs = append(errs, err)
	}
}

func addExporters(factories *component.Factories, errs []error) {
	exporters := []component.ExporterFactory{
		awsxrayexporter.NewFactory(),
	}
	for _, exp := range factories.Exporters {
		exporters = append(exporters, exp)
	}
	var err error
	factories.Exporters, err = component.MakeExporterFactoryMap(exporters...)
	if err != nil {
		errs = append(errs, err)
	}
}
