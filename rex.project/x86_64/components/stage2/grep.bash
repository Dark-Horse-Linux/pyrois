#!/bin/bash
# desc:
# stages, builds, installs

# make variables persist in subprocesses for logging function
set -a

# ----------------------------------------------------------------------
# Configuration:
# ----------------------------------------------------------------------
# the name of this application
APPNAME="grep"

# the version of this application
VERSION="3.8"

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
ARGUMENT_LIST=(
    "stage"
    "build_temp"
    "install_temp"
    "all_temp"
    "help"
)

# modes to associate with switches
# assumes you want nothing done unless you ask for it.
MODE_STAGE=false
MODE_BUILD_TEMP=false
MODE_INSTALL_TEMP=false
MODE_ALL_TEMP=false
MODE_HELP=false

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

# read defined arguments
opts=$(getopt \
    --longoptions "$(printf "%s," "${ARGUMENT_LIST[@]}")" \
    --name "$APPNAME" \
    --options "" \
    -- "$@"
)

# process supplied arguments into flags that enable execution modes
eval set --$opts
while [[ $# -gt 0 ]]; do
    case "$1" in
        --stage)
            MODE_STAGE=true
            shift 1
            ;;
        --build_temp)
            MODE_BUILD_TEMP=true
            shift 1
            ;;
        --install_temp)
            MODE_INSTALL_TEMP=true
            shift 1
            ;;
        --all_temp)
            MODE_ALL_TEMP=true
            shift 1
            ;;
        --help)
            MODE_HELP=true
            shift 1
            ;;
        *)
            break
            ;;
    esac
done

# print to stdout, print to log
logprint() {
	mkdir -p "${LOG_DIR}"
	echo "[$(date +%Y-%m-%d_%H:%M:%S)] [${APPNAME}] $1" \
	| tee -a "${LOG_DIR}/${LOGFILE}"
}

# Tell the user we're alive...
logprint "Initializing the ${APPNAME} utility..."

# when the stage mode is enabled, this will execute
mode_stage() {
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
mode_build_temp() {
	
	# patch, configure and build
	logprint "Starting build of ${APPNAME}..."
	
	logprint "Entering stage dir."	
	pushd "${T_SOURCE_DIR}"
	assert_zero $?
	
	logprint "Configuring ${APPNAME}..."
	./configure \
		--prefix=/usr \
		--host=${T_TRIPLET}
	assert_zero $?
	
	logprint "Compiling..."
	make
	assert_zero $?
	
	logprint "Build operation complete."
}

mode_install_temp() {
	logprint "Starting install of ${APPNAME}..."
	pushd "${T_SOURCE_DIR}"
	assert_zero $?
	
	logprint "Installing..."
	make DESTDIR=${T_SYSROOT} install
	assert_zero $?
	
	logprint "Install operation complete."
}


mode_help() {
	echo "${APPNAME} [ --stage ] [ --build_temp ] [ --install_temp ] [ --all_temp ] [ --help ]"
	exit 0
}

if [ "$MODE_ALL_TEMP" = "true" ]; then
	MODE_STAGE=true
	MODE_BUILD_TEMP=true
	MODE_INSTALL_TEMP=true
fi

# if no options were selected, then show help and exit
if \
	[ "$MODE_HELP" != "true" ] && \
	[ "$MODE_STAGE" != "true" ] && \
	[ "$MODE_BUILD_TEMP" != "true" ] && \
	[ "$MODE_INSTALL_TEMP" != "true" ]
then
	logprint "No option selected during execution."
	mode_help
fi

# if help was supplied at all, show help and exit
if [ "$MODE_HELP" = "true" ]; then
	logprint "Help option selected.  Printing options and exiting."
	mode_help
fi

if [ "$MODE_STAGE" = "true" ]; then
	logprint "Staging option selected."
	mode_stage
	assert_zero $?
fi

if [ "$MODE_BUILD_TEMP" = "true" ]; then
	logprint "Build of ${APPNAME} selected."
	mode_build_temp
	assert_zero $?
fi

if [ "$MODE_INSTALL_TEMP" = "true" ]; then
	logprint "Install of ${APPNAME} selected."
	mode_install_temp
	assert_zero $?
fi

logprint "Execution of ${APPNAME} completed."
