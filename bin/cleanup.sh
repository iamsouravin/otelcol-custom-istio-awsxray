#!/bin/bash

export SCRIPT_NAME=${BASH_SOURCE[0]}
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
BASE_DIR=$( cd "$SCRIPT_DIR/.." && pwd )
DEBUG=0
TMP_DIR="/tmp"
OTEL_COL_CONTRIB_PROJECT=opentelemetry-collector-contrib
OTEL_COL_CONTRIB_DIR=$TMP_DIR/$OTEL_COL_CONTRIB_PROJECT
DEP_DIR="dependencies"
ERRORS=0
WARNINGS=0

source $SCRIPT_DIR/log.sh

remove_contrib_project_directory() {
  debug "Removing '$OTEL_COL_CONTRIB_DIR' ..."
  rm -rf $OTEL_COL_CONTRIB_DIR
  
  if [ ! -d "$OTEL_COL_CONTRIB_DIR" ]; then
    debug "Directory removed successfully."
  else
    ERRORS=1
    error "Directory could not be removed completely!"
  fi
}

remove_dependencies_directory() {
  debug "Removing '$BASE_DIR/$DEP_DIR' ..."
  rm -rf $BASE_DIR/$DEP_DIR

  if [ ! -d "$BASE_DIR/$DEP_DIR" ]; then
    debug "Directory removed successfully."
  else
    ERRORS=1
    error "Directory could not be removed completely!"
  fi
}

prune_docker_builder_cache() {
  debug "Pruning docker builder cache..."
  docker builder prune -af
  if [ $? -ne 0 ]; then
    ERRORS=1
    error "Docker builder cache prune command failed!"
  else
    debug "Docker builder cache pruned successfully."
  fi
}

clean_go_cache() {
  debug "Cleaning go cache..."
  go clean -cache
  if [ $? -ne 0 ]; then
    ERRORS=1
    error "Go cache clean command failed!"
  else
    debug "Go cache cleaned successfully."
  fi
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
  echo "Usage: $SCRIPT_NAME [-h] | [[-d] -t <repo:version>]" 1>&2
  echo "" 1>&2
  echo "Arguments:" 1>&2
  echo "-d                : Enable debug logging." 1>&2
  echo "-h                : Print this usage information and exit." 1>&2
  echo "-t <repo:version> : Docker tag for docker build." 1>&2
  echo "" 1>&2
  
  exit $EXIT_CODE
}

# --- main ---

while getopts "dfht:" o; do
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

prune_docker_builder_cache

clean_go_cache

remove_contrib_project_directory

remove_dependencies_directory

cd $BASE_DIR
info "Removing docker image with tag '$IMG_REPO:$IMG_RELEASE'..."
docker image rm $IMG_REPO:$IMG_RELEASE
if [ $? -ne 0 ]; then
  ERRORS=1
  error "Docker remove image command failed."
fi

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
  info "Cleanup script done."
elif [ $ERRORS -eq 1 ]; then
  error "Cleanup script done with errors."
  exit 1
else
  warn "Cleanup script done with warnings."
fi