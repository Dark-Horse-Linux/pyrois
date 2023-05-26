#!/bin/bash
# desc:
# stages, builds, installs

# make variables persist in subprocesses for logging function
set -a
set -u

# ----------------------------------------------------------------------
# Configuration:
# ----------------------------------------------------------------------
# the name of this application
APPNAME="glibc"

# the version of this application
VERSION="2.37"

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
    "build_pass1"
    "install_pass1"
    "pass1"
    "help"
)

# modes to associate with switches
# assumes you want nothing done unless you ask for it.
MODE_STAGE=false
MODE_BUILD_PASS1=false
MODE_INSTALL_PASS1=false
MODE_PASS1=false
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
        --build_pass1)
            MODE_BUILD_PASS1=true
            shift 1
            ;;
        --install_pass1)
            MODE_INSTALL_PASS1=true
            shift 1
            ;;
        --pass1)
            MODE_PASS1=true
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
mode_build_pass1() {
	# Apply necessary symlinks
	# Adjust these for 
	# - your architecture
	# - your host distro
	
	logprint "Setting up compatibility and LSB symlinks..."
	logprint "Entering TEMP_STAGE_DIR"
	pushd ${TEMP_STAGE_DIR}
	assert_zero $?
	
	echo "rootsbindir=/usr/sbin" > ${T_SOURCE_DIR}/configparms
	assert_zero $?
	
	# fuck this part in particular!
	ln -sfv ../lib/ld-linux-x86-64.so.2 ${T_SYSROOT}/lib64
	assert_zero $?
	
	ln -sfv ../lib/ld-linux-x86-64.so.2 ${T_SYSROOT}/lib64/ld-lsb-x86-64.so.3
	assert_zero $?
	popd
	
	# patch, configure and build
	logprint "Starting build of ${APPNAME}..."
	
	logprint "Entering build dir."	
	pushd "${T_SOURCE_DIR}"
	assert_zero $?
	
	# patches
	logprint "Applying patches..."
	patch -Np1 < "${PATCHES_DIR}/glibc-2.37-fhs-1.patch"
	assert_zero $?
		
	mkdir -p build
	pushd build
	assert_zero $?
	
	logprint "Configuring ${APPNAME}..."
# surro
#	../configure \
#		--prefix=/usr \
#		--host=${T_TRIPLET} \
#		--build=$(../scripts/config.guess) \
#		--enable-kernel=3.2 \
#		--with-headers=${T_SYSROOT}/usr/include \
#		libc_cv_slibdir=/lib
# lfs/dhl
	../configure \
		--prefix=/usr \
		--host=${T_TRIPLET} \
		--build=$(../scripts/config.guess) \
		--enable-kernel=3.2 \
		--with-headers=${T_SYSROOT}/usr/include \
		libc_cv_slibdir=/usr/lib

	assert_zero $?
	
	ulimit -s 3500000
	
	logprint "Compiling..."
	make
	assert_zero $?

	logprint "Build operation complete."
}

mode_install_pass1() {
	logprint "Starting install of ${APPNAME}..."
	pushd "${T_SOURCE_DIR}/build"
	assert_zero $?
	
	logprint "Installing pass1..."
	make DESTDIR=${T_SYSROOT} install
	assert_zero $?
		
	logprint "Install operation complete."
	
	logprint "Wrapping up headers..."
	dirs -c
	pushd "${T_SOURCE_DIR}"
	assert_zero $?
	
	logprint "Cleaning up..."
	
	# TODO make this a patch
	sed '/RTLDLIST=/s@/usr@@g' -i ${T_SYSROOT}/usr/bin/ldd
	assert_zero $?

	echo
	logprint "Performing compile test:"
	pushd /tmp
	echo 'int main(){}' | ${T_TRIPLET}-gcc -xc -
	readelf -l a.out | grep ld-linux
	echo 
	echo "Which linker do you see?"
	echo "Should read: /lib64/ld-linux-x86-64.so.2"
	rm -v a.out
	assert_zero $?
	
	${CROSSTOOLS_DIR}/libexec/gcc/${T_TRIPLET}/12.2.0/install-tools/mkheaders
	assert_zero $?
	

}


mode_help() {
	echo "${APPNAME} [ --stage ] [ --build_pass1 ] [ --install_pass1 ] [ --pass1 ] [ --help ]"
	exit 0
}

# MODE_PASS1 is a meta toggle for all pass1 modes.  Modes will always 
# run in the correct order.
if [ "$MODE_PASS1" = "true" ]; then
	MODE_STAGE=true
	MODE_BUILD_PASS1=true
	MODE_INSTALL_PASS1=true
fi

# if no options were selected, then show help and exit
if \
	[ "$MODE_HELP" != "true" ] && \
	[ "$MODE_STAGE" != "true" ] && \
	[ "$MODE_BUILD_PASS1" != "true" ] && \
	[ "$MODE_INSTALL_PASS1" != "true" ]
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

if [ "$MODE_BUILD_PASS1" = "true" ]; then
	logprint "Build of PASS1 selected."
	mode_build_pass1
	assert_zero $?
fi

if [ "$MODE_INSTALL_PASS1" = "true" ]; then
	logprint "Install of PASS1 selected."
	mode_install_pass1
	assert_zero $?
fi

logprint "Execution of ${APPNAME} completed."
