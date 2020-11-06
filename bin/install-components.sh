#!/bin/bash

export SCRIPT_NAME=${BASH_SOURCE[0]}
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
BASE_DIR=$( cd "$SCRIPT_DIR/.." && pwd )
DEBUG=0
EXAMPLES_DIR=docs/examples/
K8S_MANIFEST=otelcol-custom-istio-awsxray-manifest.yaml

source $SCRIPT_DIR/log.sh

install_collector() {
  cd $BASE_DIR
  info "Installing collector..."
  kubectl apply -f $EXAMPLES_DIR/$K8S_MANIFEST
}

download_istio() {
  cd $BASE_DIR
  debug "Checking if istio directory exists..."
  ISTIO_DIR=`ls -A1dt istio-* | head -1`
  if [ -z "$ISTIO_DIR" ]; then
    debug "Directory does not exist. Downloading latest version of istio..."
    curl --silent -L https://istio.io/downloadIstio | sh -
    ISTIO_DIR=`ls -A1dt istio-* | head -1`
  else
    debug "Directory already exists."
  fi
}

install_istio() {
  cd $BASE_DIR/$ISTIO_DIR
  info "Installing istio..."
  ./bin/istioctl manifest install -f $BASE_DIR/$EXAMPLES_DIR/tracing.yaml \
  --set values.global.tracer.zipkin.address=zipkin.tracing:9411
}

mark_default_namespace() {
  info "Marking 'default' namespace for automatic proxy injection..."
  kubectl label namespace default istio-injection=enabled --overwrite
}

install_bookinfo() {
  cd $BASE_DIR/$ISTIO_DIR
  info "Installing sample bookinfo app..."
  kubectl apply -f ./samples/bookinfo/platform/kube/bookinfo.yaml
  info "Installing ingress for bookinfo app..."
  kubectl apply -f ./samples/bookinfo/networking/bookinfo-gateway.yaml

  export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
  export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')
  export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].port}')
  export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT
  info "http://$GATEWAY_URL/productpage"
}

usage() {
  EXIT_CODE=0
  if [ ! -z "$1" ]; then
    EXIT_CODE=$1
  fi

  if [ ! -z "$2" ]; then
    echo "$SCRIPT_NAME: $2"
  fi

  echo "" 1>&2
  echo "Usage: $SCRIPT_NAME [[-h] | [-d]]" 1>&2
  echo "" 1>&2
  echo "Arguments:" 1>&2
  echo "-d                : Enable debug logging." 1>&2
  echo "-h                : Print this usage information and exit." 1>&2
  echo "" 1>&2
  
  exit $EXIT_CODE
}

# --- main ---

while getopts "hd" o; do
  case "${o}" in
    d)
      DEBUG=1
      ;;
    h)
      usage
      ;;
    *)
      usage 1
      ;;
  esac
done
shift $((OPTIND-1))

info "Project Directory: $BASE_DIR"

install_collector

download_istio

install_istio

mark_default_namespace

install_bookinfo