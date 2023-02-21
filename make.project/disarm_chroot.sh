#!/bin/bash
APPNAME="CHROOT VKFS SETUP"

# ISO 8601 variation
TIMESTAMP="$(date +%Y-%m-%d_%H:%M:%S)"
T_SYSROOT=${dir_sysroot}
LOG_DIR="${dir_logs}/${APPNAME}-${TIMESTAMP}"

# the file to log to
LOGFILE="${APPNAME}.log"

assert_zero() {
	if [[ "$1" -eq 0 ]]; then 
		return
	else
		exit $1
	fi
}

logprint() {
	mkdir -p "${LOG_DIR}"
	echo "[$(date +%Y-%m-%d_%H:%M:%S)] [${APPNAME}] $1" \
	| tee -a "${LOG_DIR}/${LOGFILE}"
}

is_mounted() {
	findmnt $1 &> /dev/null
	if [ $? != 0 ]; then
		logprint "Not mounted, skipping."
		/usr/bin/false
	else
		/usr/bin/true
	fi
}

logprint "Unmounting CHROOT VFKS mounts"

logprint "Unmounting ${T_SYSROOT}/dev"
is_mounted ${T_SYSROOT}/dev && umount -l ${T_SYSROOT}/dev

logprint "Unmounting ${T_SYSROOT}/dev/pts"
is_mounted ${T_SYSROOT}/dev/pts && umount -l ${T_SYSROOT}/dev/pts

logprint "Unmounting ${T_SYSROOT}/proc"
is_mounted ${T_SYSROOT}/proc && umount -l ${T_SYSROOT}/proc

# not a symlink on ubuntu
logprint "Unmounting ${T_SYSROOT}/dev/shm"
is_mounted ${T_SYSROOT}/dev/shm && umount -l ${T_SYSROOT}/dev/shm

logprint "Unmounting pyrois inside of chroot"
is_mounted ${T_SYSROOT}/rex_embedded && umount -l ${T_SYSROOT}/rex_embedded

echo
logprint "You can now safely delete the chroot."
echo

