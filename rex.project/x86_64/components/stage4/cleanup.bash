#!/bin/bash
# desc:
# stages, builds, installs

# make variables persist in subprocesses for logging function
set -a

APPNAME="post-stage4-cleanup"


# the file to log to
LOGFILE="${APPNAME}.log"

# ISO 8601 variation
TIMESTAMP="$(date +%Y-%m-%d_%H:%M:%S)"

# the path where logs are written to
# note: LOGS_ROOT is sourced from environment
LOG_DIR="${LOGS_ROOT}/${APPNAME}-${TIMESTAMP}"


# print to stdout, print to log
logprint() {
	mkdir -p "${LOG_DIR}"
	echo "[$(date +%Y-%m-%d_%H:%M:%S)] [${APPNAME}] $1" \
	| tee -a "${LOG_DIR}/${LOGFILE}"
}

# Tell the user we're alive...
logprint "Initializing the ${APPNAME} utility..."

logprint "Cleanup of /tmp"
rm -rf /tmp/*
assert_zero $?

logprint "Erasing libtool archive files"
find /usr/lib /usr/libexec -name \*.la -delete
assert_zero $?

logprint "Deleting temporary toolchain..."
find /usr -depth -name ${T_TRIPLET}\* | xargs rm -vrf
assert_zero $?

# TODO better integrate test user lifecycle

logprint "Execution of ${APPNAME} completed."
