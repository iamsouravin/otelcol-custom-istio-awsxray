#!/bin/bash

log() {
  DT_PREFIX=`date +"%FT%T%Z"`
  printf -v LOG_LEVEL "[%-5s]" $1
  echo "[$DT_PREFIX] $LOG_LEVEL [$SCRIPT_NAME] - $2"
}

error() {
  log ERROR "$1"  
}

warn() {
  log WARN "$1"  
}

info() {
  log INFO "$1"
}

debug() {
  if [ "$DEBUG" -eq "1" ]; then
    log DEBUG "$1"
  fi
}