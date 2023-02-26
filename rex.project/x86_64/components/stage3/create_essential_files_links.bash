#!/bin/bash
# Prepares sysroot ownership and perms for chrooting
# print to stdout, print to log
# the path where logs are written to
# note: LOGS_ROOT is sourced from environment

APPNAME="Creating Essential Files and Symlinks"

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

logprint "Creating Essential Files and Symlinks"


# this may need an alternative approach when we shift deliverables towards an install iso
logprint "Generating /etc/mtab from /proc/self/mounts"
ln -sv /proc/self/mounts /etc/mtab
assert_zero $?

logprint "Staging /etc/hosts file"
cp -f ${CONFIGS_DIR}/etc_hosts 		/etc/hosts
assert_zero $?

logprint "creating a temporary user and group for some tests later"
echo "tester:x:101:101::/home/tester:/bin/bash" >> /etc/passwd
assert_zero $?
echo "tester:x:101:" >> /etc/group
assert_zero $?

logprint "creating the tester user home dir"
install -o tester -d /home/tester
assert_zero $?

logprint "creating log placeholders for login/agetty/init/btmp/lastlog"
touch /var/log/{btmp,lastlog,faillog,wtmp}
assert_zero $?

chgrp -v utmp /var/log/lastlog
assert_zero $?

chmod -v 664  /var/log/lastlog
assert_zero $?

chmod -v 600  /var/log/btmp
assert_zero $?
