#!/bin/bash
# move this to the makefile as a dedicated target

APPNAME="Offer Backup"

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

logprint "Giving the user the option of backing up before proceeding."

is_mounted() {
	findmnt $1 &> /dev/null
	if [ $? != 0 ]; then
		logprint "Not mounted...skipping."
		/usr/bin/false
	else
		logprint "Mounted..."
		/usr/bin/true
	fi
}

function disarm_chroot() {
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
}

function clear_stage() {
	pushd ${project_root}
	make clean
}


function restore() {
	# select a backup file
	FILE=$(dialog --title "Choose a restore point." --stdout --title "Please choose an archive to restore from." --fselect ${project_root} 14 48)
	
	
	logprint "Entering backup routine."
	disarm_chroot
	disarm_chroot
	logprint "Restoring backup...This will take a long time..."
	tar xpf $FILE
	assert_zero $?
	
	logprint "Backup restored successfully.  Arming chroot."
	pushd ${project_root}
	assert_zero $?
	make arm_chroot
	echo
	logprint "You may now proceed to run 'make build_stage4' or higher."
	echo
}


read -r -d '' yn_msg <<-'EOF'
Restore from backup?
EOF

# Use the dialog utility to prompt the user with a yes/no question
dialog --backtitle "Dark Horse Linux: Pyrois" --title "Restore From Backup" --yesno "$yn_msg" 10 60
response=$?

if [ $response -eq 0 ]; then
	logprint "User selected to perform backups."
	restore
else
	logprint "User canceled.  Moving on."
	exit 0
fi
