#!/bin/bash

export SCRIPT_NAME=${BASH_SOURCE[0]}
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
BASE_DIR=$( cd "$SCRIPT_DIR/.." && pwd )
DEBUG=0
EXAMPLES_DIR=docs/examples
K8S_MANIFEST=otelcol-custom-istio-awsxray-manifest.yaml

source $SCRIPT_DIR/log.sh

uninstall_collector() {
  cd $BASE_DIR
  info "Uninstalling collector..."
  kubectl delete -f $BASE_DIR/$EXAMPLES_DIR/$K8S_MANIFEST
}

check_istio_directory() {
  cd $BASE_DIR
  info "Checking if istio directory exists..."
  ISTIO_DIR=`ls -A1dt istio-* | head -1`
  if [ -z "$ISTIO_DIR" ]; then
    info "Istio directory does not exist."
    return
  fi
}

uninstall_istio() {
  if [ -z "$ISTIO_DIR" ]; then
    info "Skipping uninstallation."
    return
  fi
  cd $BASE_DIR/$ISTIO_DIR
  info "Uninstalling istio..."
  ./bin/istioctl manifest generate -f $BASE_DIR/$EXAMPLES_DIR/tracing.yaml \
  --set values.global.tracer.zipkin.address=zipkin.tracing:9411 \
  | kubectl delete -f -
}

unmark_default_namespace() {
  info "Unmarking 'default' namespace for automatic proxy injection..."
  kubectl label namespace default istio-injection-
}

uninstall_bookinfo() {
  cd $BASE_DIR/$ISTIO_DIR
  info "Uninstalling ingress for bookinfo app..."
  kubectl delete -f ./samples/bookinfo/networking/bookinfo-gateway.yaml
  info "Uninstalling sample bookinfo app..."
  kubectl delete -f ./samples/bookinfo/platform/kube/bookinfo.yaml
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
  echo "Usage: $SCRIPT_NAME [-h] [-d]" 1>&2
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

check_istio_directory

uninstall_bookinfo

uninstall_istio

unmark_default_namespace

uninstall_collector