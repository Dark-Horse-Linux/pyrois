#!/bin/bash
APPNAME="CHROOT VFS SETUP"
T_SYSROOT=${dir_sysroot}

assert_zero() {
	if [[ "$1" -eq 0 ]]; then 
		return
	else
		exit $1
	fi
}

# ISO 8601 variation
TIMESTAMP="$(date +%Y-%m-%d_%H:%M:%S)"

LOG_DIR="${dir_logs}/${APPNAME}-${TIMESTAMP}"

# the file to log to
LOGFILE="${APPNAME}.log"

logprint() {
	mkdir -p "${LOG_DIR}"
	echo "[$(date +%Y-%m-%d_%H:%M:%S)] [${APPNAME}] $1" \
	| tee -a "${LOG_DIR}/${LOGFILE}"
}

/usr/sbin/chroot "${T_SYSROOT}" /usr/bin/env -i   \
    HOME=/root                  \
    TERM="$TERM"                \
    PS1='\n(dark horse linux) [ \u @ \H ] << \w >>\n\n[- ' \
    PATH=/usr/bin:/usr/sbin     \
    /bin/bash --login
