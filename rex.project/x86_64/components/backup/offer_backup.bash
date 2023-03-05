#!/bin/bash
# move this to the makefile as a dedicated target

APPNAME="Offer Backup"

# ISO 8601 variation
TIMESTAMP="$(date +%Y-%m-%d_%H%M%S)"

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

function perform_backup() {
	logprint "Entering backup routine."
	disarm_chroot
	disarm_chroot
	logprint "Performing backup...This will take a long time..."
	pushd ${dir_artifacts}
	tar cpzf ${project_root}/${TIMESTAMP}.backup.tgz *
	assert_zero $?
	logprint "Backup completed successfully.  Moving on."
	logprint "Entering project root."
	pushd ${project_root}
	assert_zero $?
	logprint "Re-arming chroot..."
	make arm_chroot
	echo
	logprint "You may now proceed to run 'make build_stage4'."
	echo
}


read -r -d '' msg <<-'EOF'
This is a great stopping point for backing up the stage if you're 
debugging.  The following prompt will ask if you'd like to back up the 
existing sysroot, in case you need to start from stage 4 again for 
whatever reason, such as a build failure.

If you select yes, you will see a gzipped tarball containing the 
sysroot generated in your project root.  If you select no, your backup 
will not be created, and you'll move on to stage 4.  

If you skip the backup and something fails from here, you'll need to
run "make clean" and start from the beginning.

If you do decide to back up, which you should, should you need to 
restore from your backup, simply running "make restore" will perform 
the operations necessary.
EOF

read -r -d '' yn_msg <<-'EOF'
Do you want to back up the stage?

If you select yes, the VKFS mounts for the chroot will be unmounted temporarily to perform this operation.
EOF

# Use the dialog utility to display information to the user
dialog --backtitle "Dark Horse Linux: Pyrois" --title "IMPORTANT NOTICE" --msgbox  "$msg" 20 78

# Use the dialog utility to prompt the user with a yes/no question
dialog --backtitle "Dark Horse Linux: Pyrois" --title "Back up the stage?" --yesno "$yn_msg" 10 60
response=$?

if [ $response -eq 0 ]; then
	logprint "User selected to perform backups."
	perform_backup
else
	logprint "User selected to skip backups.  Moving on."
	exit 0
fi
