#!/bin/bash
# Prepares sysroot ownership and perms for chrooting
# print to stdout, print to log
# the path where logs are written to
# note: LOGS_ROOT is sourced from environment
set -u

APPNAME="CHROOT VFS SETUP"

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

is_mounted() {
	findmnt $1 &> /dev/null
	if [ $? != 0 ]; then
		/usr/bin/false
	else
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

logprint "mounting pyrois inside of chroot"
mkdir -p ${T_SYSROOT}/rex_embedded
is_mounted ${project_root} || mount -v --bind ${project_root} ${T_SYSROOT}/rex_embedded
assert_zero $?

# not a symlink on ubuntu
if [ -h ${T_SYSROOT}/dev/shm ]; then
	mkdir -vp ${T_SYSROOT}/$(readlink ${T_SYSROOT})/dev/shm
	assert_zero $?
else
	mount -t tmpfs -o nosuid,nodev tmpfs ${T_SYSROOT}/dev/shm
fi

# don't remember what this was for
#logprint "Creating mount point for project root."
#mkdir -pv ${T_SYSROOT}/${PROJECT_ROOT}
#assert_zero $?

## source these majors and minors
#logprint "Creating block device for console..."
#sudo rm -f ${T_SYSROOT}/dev/console
#mknod -m 600 ${T_SYSROOT}/dev/console c 5 1
#assert_zero $?

# source these majors and minors
#logprint "Create block device for null..."
#sudo rm -f ${T_SYSROOT}/dev/null
#mknod -m 666 ${T_SYSROOT}/dev/null c 1 3

#logprint "mounting /sys filesystem from to chroot sysroot..."
#is_mounted ${T_SYSROOT}/sys || mount -v -t sysfs sysfs ${T_SYSROOT}/sys
#assert_zero $?

#logprint "mounting tmpfs/run filesystem from to chroot sysroot..."
#is_mounted ${T_SYSROOT}/run || mount -v -t tmpfs tmpfs ${T_SYSROOT}/run
#assert_zero $?

#logprint "bind mounting stage 2 files for posterity!"
#is_mounted ${T_SYSROOT}${PROJECT_ROOT} || mount -v --bind ${PROJECT_ROOT} ${T_SYSROOT}${PROJECT_ROOT}
#assert_zero $?

#logprint "Copy Rex to Chroot"
#mkdir -p ${T_SYSROOT}/usr/local/bin
#stat ${T_SYSROOT}/usr/local/bin/rex 2>/dev/null || cp -Rf /usr/local/bin/rex ${T_SYSROOT}/usr/local/bin/rex
#assert_zero $?
