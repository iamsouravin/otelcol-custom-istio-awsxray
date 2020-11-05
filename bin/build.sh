#!/bin/bash

export SCRIPT_NAME=${BASH_SOURCE[0]}
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
BASE_DIR=$( cd "$SCRIPT_DIR/.." && pwd )
DEBUG=0
TMP_DIR="/tmp"
OTEL_COL_CONTRIB_PROJECT=opentelemetry-collector-contrib
GIT_CLONE_URL=https://github.com/iamsouravin/$OTEL_COL_CONTRIB_PROJECT.git
OTEL_COL_CONTRIB_DIR=$TMP_DIR/$OTEL_COL_CONTRIB_PROJECT
EXPORTER_PROJECT=awsxrayexporter
BRANCH=istio-build
EXAMPLES_DIR=docs/examples/
K8S_MANIFEST_TEMPLATE=otelcol-custom-istio-awsxray-manifest.template
K8S_MANIFEST=otelcol-custom-istio-awsxray-manifest.yaml
DEP_DIR="dependencies/$EXPORTER_PROJECT"

source $SCRIPT_DIR/log.sh

copy_contrib_project() {
  debug "Checking if '$BASE_DIR/$DEP_DIR' directory is empty..."
  DIR_LST=$(ls -A $BASE_DIR/$DEP_DIR)
  if [ -z "$DIR_LST" ]; then
    debug "Directory is empty..."
    
    debug "Checking if '$OTEL_COL_CONTRIB_DIR' directory exists..."
    if [ ! -d "$OTEL_COL_CONTRIB_DIR" ]; then
      debug "Directory does not exist."

      debug "Changing to $TMP_DIR..."
      cd $TMP_DIR

      git_clone_project

      git_checkout_project

    else
      git_checkout_project
      
      git_pull_latest

    fi

    debug "Changing into '$BASE_DIR/dependencies' directory..."
    cd $BASE_DIR/dependencies

    debug "Copying '$EXPORTER_PROJECT' project directory into '$BASE_DIR/dependencies'..."
    cp -r $OTEL_COL_CONTRIB_DIR/exporter/$EXPORTER_PROJECT ./
  else
    debug "Directory is not empty. Skipping copy step."
  fi
}

create_dependencies_directory() {
  debug "Checking if '$BASE_DIR/$DEP_DIR' directory exists..."
  if [ ! -d "$BASE_DIR/$DEP_DIR" ]; then
    debug "Directory does not exist."
    cd $BASE_DIR
    debug "Creating directory..."
    mkdir -p $BASE_DIR/$DEP_DIR

  else
    debug "Directory already exists."
  fi
}

git_pull_latest() {
  debug "Pulling latest from 'origin/$BRANCH'..."
  git pull origin $BRANCH -q
}

git_clone_project() {
  debug "Cloning '$GIT_CLONE_URL'..."
  git clone $GIT_CLONE_URL -q
}

git_checkout_project() {
  debug "Changing to '$TMP_DIR/$OTEL_COL_CONTRIB_PROJECT' directory..."
  cd $TMP_DIR/$OTEL_COL_CONTRIB_PROJECT
  
  debug "Checking out '$BRANCH' branch..."
  git checkout $BRANCH -q
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
  echo "Usage: $SCRIPT_NAME [-d] -t <repo:version>" 1>&2
  echo "" 1>&2
  echo "Arguments:" 1>&2
  echo "-d                : Enable debug logging." 1>&2
  echo "-h                : Print this usage information and exit." 1>&2
  echo "-t <repo:version> : Docker tag for docker build." 1>&2
  echo "" 1>&2
  
  exit $EXIT_CODE
}

# --- main ---

while getopts "hdt:" o; do
  case "${o}" in
    d)
      DEBUG=1
      ;;
    t)
      TAG=${OPTARG}
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

if [ -z "${TAG}" ]; then
  usage 1 "Tag is empty."
fi

IMG_REPO=`echo $TAG | awk -F: '{print $1}'`
IMG_RELEASE=`echo $TAG | awk -F: '{print $2}'`

if [ -z "${IMG_REPO}" ]; then
  usage 1 "repo missing from tag."
fi

if [ -z "${IMG_RELEASE}" ]; then
  usage 1 "version missing from tag."
fi

info "Image Repository: $IMG_REPO"
info "Image Version: $IMG_RELEASE"

info "Project Directory: $BASE_DIR"

create_dependencies_directory

copy_contrib_project

cd $BASE_DIR
info "Launching docker build..."
docker build -t $IMG_REPO:$IMG_RELEASE --build-arg IMG_RELEASE=$IMG_RELEASE .
if [ $? -ne 0 ]; then
  error "Docker build failed. Aborting!"
  exit 1
fi

info "Creating new manifest from template '$EXAMPLES_DIR/$K8S_MANIFEST_TEMPLATE'..."
sed "s#\$IMAGE#${TAG}#g" $EXAMPLES_DIR/$K8S_MANIFEST_TEMPLATE > $EXAMPLES_DIR/$K8S_MANIFEST
if [ $? -ne 0 ]; then
  error "Could not generate manifest file. Aborting!"
  exit 1
fi

info "Next Steps:"
info "-----------"
info "$ docker image push $IMG_REPO:$IMG_RELEASE"
info "$ $SCRIPT_DIR/install-components.sh"