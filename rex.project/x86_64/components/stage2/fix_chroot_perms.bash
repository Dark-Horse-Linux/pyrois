#!/bin/bash
# Prepares sysroot ownership and perms for chrooting
# print to stdout, print to log
# the path where logs are written to
# note: LOGS_ROOT is sourced from environment

APPNAME="FIX_CHROOT_PERMS"

# ISO 8601 variation
TIMESTAMP="$(date +%Y-%m-%d_%H:%M:%S)"

LOG_DIR="${LOGS_ROOT}/${APPNAME}-${TIMESTAMP}"

logprint() {
	mkdir -p "${LOG_DIR}"
	echo "[$(date +%Y-%m-%d_%H:%M:%S)] [${APPNAME}] $1" \
	| tee -a "${LOG_DIR}/${LOGFILE}"
}

logprint "Fixing ownership on T_SYSROOT"

chown -R root:root ${T_SYSROOT}/{usr,lib,var,etc,bin,sbin}
assert_zero $?

chown -R root:root ${CROSSTOOLS_DIR}
assert_zero $?

chown -R root:root ${ARCHLIB_DIR}
assert_zero $?

