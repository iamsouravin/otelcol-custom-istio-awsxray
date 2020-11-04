# OpenTelemetry Collector Custom Distribution for Exporting Istio Zipkin Traces to AWS X-Ray

This is a custom build of the [OpenTelemetry Collector](https://github.com/open-telemetry/opentelemetry-collector) and [OpenTelemetry Collector Contrib](https://github.com/open-telemetry/opentelemetry-collector-contrib) projects. It adds all the default components from OpenTelemetry Collector project. Only components from the OpenTelemetry Collector Contrib project that are explicitly added are included in this distribution.

The build script downloads a customized version of `awsxrayexporter` to propagate Istio proxy generated Zipkin traces to AWS X-Ray.

## Application Info

| Property | Value |
|----------|-------|
| `ExeName` | `otelcol-custom-istio-awsxray` |
| `LongName` | `OpenTelemetry Collector Custom Distribution` |
| `Version` | Image tag version used in docker build. |
| `GitHash` | Git commit hash used in docker build. |

Update the application information in `main.go`.

## Adding Components

Components are added in `components.go`.

### Methods

 * `addReceivers`
 * `addProcessors`
 * `addExporters`

## Build

Build script `bin/build.sh` checks if `dependencies` directory is present and contains the `awsxrayexport` project directory. If not then downloads the source and copies the project contents into the `dependencies` directory. After the build updates generates manifest file `docs/examples/otelcol-custom-istio-awsxray-manifest.yaml` with the image tag information.

```shell
bin/build.sh -t $ACCOUNTID.dkr.ecr.$REGION.amazonaws.com/otelcol-custom-istio-awsxray:0.1.0
```

## Run

```shell
export WORKSPACE_DIR=<workspace directory>
docker run \
--rm \
-v $WORKSPACE_DIR/docs/examples:/config/ \
-v ~/.aws:/root/.aws/ \
otelcol-custom:0.1.0
```