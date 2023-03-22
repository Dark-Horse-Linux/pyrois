#!/bin/bash
# desc:
# stages, builds, installs

# make variables persist in subprocesses for logging function
set -a

APPNAME="system-tuning"


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

# is it a system service?
# is it part of the system init?
# then it's out of scope for the init system
logprint "Disabling systemd-networkd-wait-online"
systemctl disable systemd-networkd-wait-online
assert_zero $?

logprint "Disabling systemd-resolved"
systemctl disable systemd-resolved
assert_zero $?

logprint "Setting classic names for ethernet devices..."
ln -s /dev/null /etc/systemd/network/99-default.link
assert_zero $?

# Add these to a "first-boot" script?
# --------------------------------------------
# TODO bring in networkmanager for dhcp config
# TODO same for DNS configuration
# TODO same for resolv.conf configuration
# TODO same for setting hostname (echo $hostname > /etc/hostname)
# TODO same for domain name to create fqdn in hosts file
# TODO same for time zone
# TODO same for locale 
# TODO same for fstab -- on target system only.



logprint "Disabling timesyncd"
systemctl disable systemd-timesyncd
assert_zero $?

logprint "setting up console" 
cp -vf ${CONFIGS_DIR}/etc_vconsole.conf /etc/vconsole.conf
assert_zero $?

logprint "setting default locale"
cp -vf ${CONFIGS_DIR}/etc_locale.conf /etc/locale.conf
assert_zero $?

logprint "setting inputrc"
cp -vf ${CONFIGS_DIR}/etc_inputrc /etc/inputrc
assert_zero $?

logprint "setting initial /etc/shells"
cp -vf ${CONFIGS_DIR}/etc_shells /etc/shells
assert_zero $?

# is it init?
# is it service state management?
logprint "Disabling screen clearing by systemd"
mkdir -pv /etc/systemd/system/getty@tty1.service.d
assert_zero $?

cp -vf ${CONFIGS_DIR}/etc_systemd_system_getty@tty1.service.d_noclear.conf /etc/systemd/system/getty@tty1.service.d/noclear.conf
assert_zero $?

logprint "Fixing systemd scope creep on logind.conf"
cp -vf ${CONFIGS_DIR}/etc_systemd_logind.conf /etc/systemd/logind.conf
assert_zero $?

logprint "Setting Release Files"
cp -vf ${CONFIGS_DIR}/etc_dhl-release /etc/dhl-release
assert_zero $?

cp -vf ${CONFIGS_DIR}/etc_lsb-release /etc/lsb-release
assert_zero $?

cp -vf ${CONFIGS_DIR}/etc_os-release /etc/os-release
assert_zero $?


# re: fstab, since this artifact will boot on an iso, the booting disk
# may need to be assumed
# deferring this for later testing

logprint "Execution of ${APPNAME} completed."
