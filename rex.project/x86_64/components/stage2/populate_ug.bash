#!/bin/bash
# Prepares sysroot ownership and perms for chrooting
# print to stdout, print to log
# the path where logs are written to
# note: LOGS_ROOT is sourced from environment
set -u

APPNAME="CHROOT PASSWD GROUPS"

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


logprint "Installing initial users and groups to chroot..."
cp -f ${dir_configs}/etc_passwd 	${T_SYSROOT}/etc/passwd
assert_zero $?

cp -f ${dir_configs}/etc_group 		${T_SYSROOT}/etc/group
assert_zero $?
