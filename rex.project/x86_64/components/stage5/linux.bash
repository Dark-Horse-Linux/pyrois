#!/bin/bash
# desc:
# stages, builds, installs

# make variables persist in subprocesses for logging function
set -a

# ----------------------------------------------------------------------
# Configuration:
# ----------------------------------------------------------------------
# the name of this application
APPNAME="linux"

# the version of this application
VERSION="6.0.12"

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
    "build"
    "install"
    "all"
    "help"
)

# modes to associate with switches
# assumes you want nothing done unless you ask for it.
MODE_STAGE=false
MODE_BUILD=false
MODE_INSTALL=false
MODE_ALL=false
MODE_HELP=false

# the file to log to
LOGFILE="${APPNAME}.log"

# ISO 8601 variation
TIMESTAMP="$(date +%Y-%m-%d_%H%M%S)"

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
        --build)
            MODE_BUILD=true
            shift 1
            ;;
        --install)
            MODE_INSTALL=true
            shift 1
            ;;
        --all)
            MODE_ALL=true
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
mode_build() {
	
	# patch, configure and build
	logprint "Starting build of ${APPNAME}..."
	
	logprint "Entering build dir."	
	pushd "${T_SOURCE_DIR}"
	assert_zero $?

	logprint "running make mrproper..."
	make mrproper
	assert_zero $?
		
	logprint "Configuring kernel..."
	cp -vf ${CONFIGS_DIR}/kernel_config ./.config
	assert_zero $?
		
	logprint "Compiling kernel"
	make
	assert_zero $?
	logprint "Checks exited with '$?'. "

	logprint "Build operation complete."
}

mode_install() {
	logprint "Starting install of ${APPNAME}..."
	pushd "${T_SOURCE_DIR}"
	assert_zero $?
	
	logprint "Installing modules..."
	make INSTALL_MOD_STRIP=1 modules_install
	assert_zero $?
	
	logprint "Installing kernel"
	# TODO parameterize this for cross-arch builds
	cp -iv arch/x86_64/boot/bzImage /boot/vmlinuz-${VERSION}-dark_horse-pyrois
	assert_zero $?
	
	cp -ifv System.map /boot/System.map-${VERSION}
	assert_zero $?
	
	cp -ivf .config /boot/config-${VERSION}
	assert_zero $?
	
	logprint "Installing documentation..."
	install -d /usr/share/doc/linux-${VERSION}
	assert_zero $?
	
	cp -r Documentation/* /usr/share/doc/linux-${VERSION}
	assert_zero $?
	
	logprint "Configuring USB module load order..."
	mkdir -p /etc/modprobe.d
	assert_zero $?
	
	cp -vf ${CONFIGS_DIR}/etc_modprobe.d_usb.conf /etc/modprobe.d/usb.conf
	assert_zero $?
	
	logprint "Install operation complete."
}


mode_help() {
	echo "${APPNAME} [ --stage ] [ --build_temp ] [ --install_temp ] [ --all_temp ] [ --help ]"
	exit 1
}

if [ "$MODE_ALL" = "true" ]; then
	MODE_STAGE=true
	MODE_BUILD=true
	MODE_INSTALL=true
fi

# if no options were selected, then show help and exit
if \
	[ "$MODE_HELP" != "true" ] && \
	[ "$MODE_STAGE" != "true" ] && \
	[ "$MODE_BUILD" != "true" ] && \
	[ "$MODE_INSTALL" != "true" ]
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

if [ "$MODE_BUILD" = "true" ]; then
	logprint "Build of ${APPNAME} selected."
	mode_build
	assert_zero $?
fi

if [ "$MODE_INSTALL" = "true" ]; then
	logprint "Install of ${APPNAME} selected."
	mode_install
	assert_zero $?
fi

logprint "Execution of ${APPNAME} completed."
