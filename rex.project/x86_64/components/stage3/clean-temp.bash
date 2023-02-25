#!/bin/bash
# Prepares sysroot ownership and perms for chrooting
# print to stdout, print to log
# the path where logs are written to
# note: LOGS_ROOT is sourced from environment

APPNAME="Cleaning up the Temporary System"

# ISO 8601 variation
TIMESTAMP="$(date +%Y-%m-%d_%H:%M:%S)"

LOG_DIR="${LOGS_ROOT}/${APPNAME}-${TIMESTAMP}"

# the file to log to
LOGFILE="${APPNAME}.log"

logprint() {
	mkdir -p "${LOG_DIR}"
	echo "[$(date +%Y-%m-%d_%H:%M:%S)] [${APPNAME}] $1" \
	| tee -a "${LOG_DIR}/${LOGFILE}"
}

logprint "Cleaning up the Temporary System"


# this may need an alternative approach when we shift deliverables towards an install iso
logprint "Removing temp documentation files..."
rm -rvf /usr/share/{info,man,doc}/*
assert_zero $?

logprint "Removing temp libtool artifacts..."
find /usr/{lib,exec} -name \*.la -delete
assert_zero $?

logprint "Cleaning out Temporary Cross-Compilation Toolchain"
rm -Rf ${CROSSTOOLS_DIR}
assert_zero $?
