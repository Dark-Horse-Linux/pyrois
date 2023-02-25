#!/bin/bash
# Prepares sysroot ownership and perms for chrooting
# print to stdout, print to log
# the path where logs are written to
# note: LOGS_ROOT is sourced from environment

APPNAME="Creating system directories"

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

logprint "Creating system directories..."

mkdir -pv /{boot,home,mnt,opt,srv}
assert_zero $?

mkdir -pv /etc/{opt,sysconfig}
assert_zero $?

mkdir -pv /lib/firmware
assert_zero $?

mkdir -pv /media/{floppy,cdrom}
assert_zero $?

mkdir -pv /usr/{,local/}{include,src}
assert_zero $?

mkdir -pv /usr/local/{bin,lib,sbin}
assert_zero $?

mkdir -pv /usr/{,local/}share/{color,dict,doc,info,locale,man}
assert_zero $?

mkdir -pv /usr/{,local/}share/{misc,terminfo,zoneinfo}
assert_zero $?

mkdir -pv /usr/{,local/}share/man/man{1..8}
assert_zero $?

mkdir -pv /var/{cache,local,log,mail,opt,spool}
assert_zero $?

mkdir -pv /var/lib/{color,misc,locate}
assert_zero $?

ln -sfv /run /var/run
assert_zero $?

ln -sfv /run/lock /var/lock
assert_zero $?

install -dv -m 0750 /root
assert_zero $?

install -dv -m 1777 /tmp /var/tmp
assert_zero $?

# additional FHS compliance directories go here
# these are only a subset

