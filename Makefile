GOOS?=linux
GOARCH?=amd64
GOBIN:=$(shell pwd)/.bin

IMG_REPO?=iamsouravin/otelcol-custom-istio-awsxray
IMG_VERSION?=0.1.0
GIT_REPO?=$(shell git config --get remote.origin.url)
GIT_COMMIT?=$(shell git rev-parse --short HEAD)

VERSION_PKG=github.com/iamsouravin/otelcol-custom-istio-awsxray/version
VERSION_LD_FLAGS=-X $(VERSION_PKG).RELEASE=$(IMG_VERSION) -X $(VERSION_PKG).REPO=$(GIT_REPO) -X $(VERSION_PKG).COMMIT=$(GIT_COMMIT)
COMPILE_OUTPUT?=otelcol-custom-istio-awsxray

all: compile

.PHONY: compile
compile:
	CGO_ENABLED=0 GOOS=$(GOOS) GOARCH=$(GOARCH) go build -ldflags="-s -w $(VERSION_LD_FLAGS)" -a -installsuffix cgo  -o ${COMPILE_OUTPUT} .
