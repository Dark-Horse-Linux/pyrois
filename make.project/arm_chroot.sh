#!/bin/bash
APPNAME="CHROOT VFS SETUP"
T_SYSROOT=${dir_sysroot}
set -a
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

is_mounted() {
	findmnt $1 &> /dev/null
	if [ $? != 0 ]; then
		/usr/bin/false
	else
		logprint "Already mounted, skipping."
		/usr/bin/true
	fi
}

logprint "CHROOT VFS SETUP"

mkdir -pv ${T_SYSROOT}/{dev,proc,sys,run}
assert_zero $?

logprint "Bind mounting /dev from host to chroot sysroot..."
is_mounted ${T_SYSROOT}/dev || mount -v --bind /dev ${T_SYSROOT}/dev
assert_zero $?

logprint "Bind mounting /dev/pts from host to chroot sysroot..."
is_mounted ${T_SYSROOT}/dev/pts || mount -v --bind /dev/pts ${T_SYSROOT}/dev/pts
assert_zero $?

logprint "mounting proc filesystem from to chroot sysroot..."
is_mounted ${T_SYSROOT}/proc || mount -v -t proc proc ${T_SYSROOT}/proc
assert_zero $?

logprint "mounting shm"
# not a symlink on ubuntu
if [ -h ${T_SYSROOT}/dev/shm ]; then
	mkdir -vp ${T_SYSROOT}/$(readlink "${T_SYSROOT}/dev/shm")
	assert_zero $?
else
	is_mounted ${T_SYSROOT}/dev/shm || mount -t tmpfs -o nosuid,nodev tmpfs ${T_SYSROOT}/dev/shm
fi

logprint "mounting rex_embedded for stage3 capability"
mkdir -p ${T_SYSROOT}/rex_embedded
is_mounted ${T_SYSROOT}/rex_embedded || mount -v --bind ${project_root} ${T_SYSROOT}/rex_embedded
