#!/bin/bash
# desc:
# stages, builds, installs

# make variables persist in subprocesses for logging function
set -a

# ----------------------------------------------------------------------
# Configuration:
# ----------------------------------------------------------------------
# the name of this application
APPNAME="util-linux"

# the version of this application
VERSION="2.36.2"

# ----------------------------------------------------------------------
# Variables and functions sourced from Environment:
# ----------------------------------------------------------------------
# assert_zero()
# Checks if $1 is 0.  If non-0 value, halts the execution of the script.
#
# LOGS_ROOT
# The parent directory where logs from this project will go.
#
# TEMP_STAGE_DIR
# The parent directory of where source archives are extracted to.

# register mode selections

# the file to log to
LOGFILE="${APPNAME}.log"

# ISO 8601 variation
TIMESTAMP="$(date +%Y-%m-%d_%H:%M:%S)"

# the path where logs are written to
# note: LOGS_ROOT is sourced from environment
LOG_DIR="${LOGS_ROOT}/${APPNAME}-${TIMESTAMP}"

# the path where the source will be located when complete
# note: TEMP_STAGE_DIR is sourced from environment
T_SOURCE_DIR="${TEMP_STAGE_DIR}/${APPNAME}"

# print to stdout, print to log
logprint() {
	mkdir -p "${LOG_DIR}"
	echo "[$(date +%Y-%m-%d_%H:%M:%S)] [${APPNAME}] $1" \
	| tee -a "${LOG_DIR}/${LOGFILE}"
}

# Tell the user we're alive...
logprint "Initializing the ${APPNAME} utility..."

# when the stage mode is enabled, this will execute
stage() {
	logprint "Starting stage of ${APPNAME}..."

	logprint "Removing any pre-existing staging for ${APPNAME}."
	rm -Rf "${T_SOURCE_DIR}"*

	logprint "Extracting ${APPNAME}-${VERSION} source archive to ${TEMP_STAGE_DIR}"
	tar xf "${SOURCES_DIR}/${APPNAME}-${VERSION}.tar."* -C "${TEMP_STAGE_DIR}"
	assert_zero $?

	# conditionally rename if it needs it
	stat "${T_SOURCE_DIR}-"* && mv "${T_SOURCE_DIR}-"* "${T_SOURCE_DIR}"

	logprint "Staging operation complete."
}

# when the build_pass1 mode is enabled, this will execute
build() {
	# patch, configure and build
	logprint "Starting build of temporary getopt from ${APPNAME}..."

	logprint "Creating hwclock dir..."
	mkdir -pv ${T_SYSROOT}/var/lib/hwclock
	
	logprint "Entering stage dir."	
	pushd "${T_SOURCE_DIR}"
	assert_zero $?
	
	logprint "Configuring ${APPNAME}..."
	./configure ADJTIME_PATH=/var/lib/hwclock/adjtime \
		--docdir=/usr/share/doc/util-linux-2.36.2 \
		--disable-chfn-chsh \
		--disable-login \
		--disable-nologin \
		--disable-su \
		--disable-setpriv \
		--disable-runuser \
		--disable-pylibmount \
		--disable-static \
		--without-python \
		runstatedir=/run
	assert_zero $?
	
	logprint "Compiling..."
	make
	assert_zero $?
	
	logprint "Build operation complete."
}

install_getopt() {
	logprint "Starting install of ${APPNAME}..."
	pushd "${T_SOURCE_DIR}"
	assert_zero $?
	
	logprint "Installing getopt..."
	cp -v ./getopt ${T_SYSROOT}/usr/local/bin/getopt
	assert_zero $?
	
	logprint "Install operation complete."
}

stage
build
install_getopt
logprint "Execution of ${APPNAME} completed."

