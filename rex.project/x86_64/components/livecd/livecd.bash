#!/bin/bash
# desc:
# stages, builds, installs

# make variables persist in subprocesses for logging function
set -a

APPNAME="livecd"


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

logprint "Creating grub boot directory..."
mkdir -p ${T_SYSROOT}/boot/grub
assert_zero $? 


logprint "Installing livecd grub config" 
cp -vf ${CONFIGS_DIR}/boot_grub_grub.cfg ${T_SYSROOT}/boot/grub/grub.cfg
assert_zero $?

pushd ${dir_artifacts}
assert_zero $?

logprint "Emptying source stage..."
rm -Rf ${TEMP_STAGE_DIR}
assert_zero $?

rm -Rf /rex_embedded
assert_zero $?

logprint "Generating initramfs..."
# TODO chroot ignores this, and it breaks binutils pass 3
ulimit -n 3000000
/usr/sbin/chroot "${T_SYSROOT}" /usr/bin/env -i   \
    HOME=/root                  \
    TERM="xterm-256color"                \
    PS1='\n(dark horse linux) [ \u @ \H ] << \w >>\n\n[- ' \
    PATH=/usr/bin:/usr/sbin     \
    dracut --force '' 6.0.12
assert_zero $?

logprint "Generating bootable ISO"
grub2-mkrescue -o DHLP.iso ${T_SYSROOT}
assert_zero $?

logprint "Thanks for using Dark Horse Linux.  Your experimental build is at '${dir_artifacts}/DHLP.iso'."
logprint "You can test your new ISO with qemu using:"
logprint "qemu-system-x86_64 -cdrom ${dir_artifacts}/DHLP.iso -m 2048 -boot d"

logprint "Execution of ${APPNAME} completed."
