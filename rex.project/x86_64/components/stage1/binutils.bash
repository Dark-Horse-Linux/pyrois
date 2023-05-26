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
APPNAME="binutils"

# the version of this application
#VERSION="2.25"
VERSION="2.40"

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
    "build_pass2"
    "install_pass2"
    "pass2"
    "build_pass3"
    "install_pass3"
    "pass3"
    "help"
)

# modes to associate with switches
# assumes you want nothing done unless you ask for it.
MODE_STAGE=false
MODE_BUILD_PASS1=false
MODE_INSTALL_PASS1=false
MODE_PASS1=false
MODE_BUILD_PASS2=false
MODE_INSTALL_PASS2=false
MODE_PASS2=false
MODE_BUILD_PASS3=false
MODE_INSTALL_PASS3=false
MODE_PASS3=false
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

# sourced from environment
TEMP_STAGE_DIR=${TEMP_STAGE_DIR}
whoami
ls -l ${TEMP_STAGE_DIR}/../ | grep ${TEMP_STAGE_DIR}
mkdir -p ${TEMP_STAGE_DIR}

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
        --build_pass2)
            MODE_BUILD_PASS2=true
            shift 1
            ;;
        --install_pass2)
            MODE_INSTALL_PASS2=true
            shift 1
            ;;
        --pass2)
            MODE_PASS2=true
            shift 1
            ;;
        --build_pass3)
            MODE_BUILD_PASS3=true
            shift 1
            ;;
        --install_pass3)
            MODE_INSTALL_PASS3=true
            shift 1
            ;;
        --pass3)
            MODE_PASS3=true
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
	rm -Rf "${T_SOURCE_DIR}"

	logprint "Extracting ${APPNAME}-${VERSION} source archive to ${TEMP_STAGE_DIR}"
	tar xf "${SOURCES_DIR}/${APPNAME}-${VERSION}.tar."* -C "${TEMP_STAGE_DIR}" \
	|| $( logprint "Couldn't locate source tarball.  Did you run \`make download_sources\`?" \
	&& assert_zero 127 )

	logprint "Extraction complete...Renaming directory "
	# conditionally rename if it needs it
	stat "${T_SOURCE_DIR}-"* && mv "${T_SOURCE_DIR}-"* "${T_SOURCE_DIR}" 
	assert_zero $?

	logprint "Staging operation complete."
}

# when the build_pass1 mode is enabled, this will execute
mode_build_pass1() {
	logprint "Starting build of ${APPNAME}..."
	
	logprint "Entering build dir."	
	pushd "${T_SOURCE_DIR}"
	
	# sourced from environment:  checks $? -- aborts script execution if non-zero
	assert_zero $?

	mkdir -p build
	pushd build
	assert_zero $?
	
	logprint "Configuring binutils pass1..."
	../configure \
		--prefix=${CROSSTOOLS_DIR} \
		--with-sysroot=${T_SYSROOT} \
		--target=${T_TRIPLET} \
		--disable-nls \
		--disable-werror
	assert_zero $?
	
	logprint "Compiling..."
	make
	assert_zero $?

	logprint "Build operation complete."
}

mode_build_pass2() {
	logprint "Starting build of ${APPNAME}..."
	
	logprint "Entering build dir."	
	pushd "${T_SOURCE_DIR}"
	assert_zero $?

	# hrmmmmmm....
	logprint "Hack to fix bundled libtool..."
	sed '6009s/$add_dir//' -i ltmain.sh
	assert_zero $?

	logprint "Entering build subdir"
	mkdir -p build
	pushd build
	assert_zero $?
	
	logprint "Configuring binutils pass2..."
	../configure \
		--prefix=/usr \
		--build=$(../config.guess) \
		--host=${T_TRIPLET} \
		--disable-nls \
		--enable-shared \
		--enable-gprofng=no \
		--disable-werror \
		--enable-64-bit-bfd
	assert_zero $?
	
	logprint "Compiling..."
	make
	assert_zero $?

	logprint "Build operation complete."
}

mode_build_pass3() {
	echo -n "3000000" >/proc/sys/fs/file-max
	ulimit -n 3000000
	ulimit -a
	
	logprint "Starting build of ${APPNAME}..."
	
	logprint "Entering build dir."	
	pushd "${T_SOURCE_DIR}"
	assert_zero $?
	
	logprint "Checking for PTY viability..."

	expect -c 'spawn bash -c "echo test > /dev/pts/1"; expect "test"; exit [catch wait]'
	assert_zero $?
	
	mkdir -pv build
	assert_zero $?
	pushd build
	assert_zero $?
	
	logprint "Configuring ${APPNAME}..."
	../configure \
		--prefix=/usr \
		--sysconfdir=/etc \
		--enable-gold \
		--enable-ld=default \
		--enable-plugins \
		--enable-shared \
		--disable-werror \
		--enable-64-bit-bfd \
		--with-system-zlib
		
	assert_zero $?
	
	logprint "Compiling..."
	make tooldir=/usr
	assert_zero $?

	logprint "Testing..."
	err=0
	# these flags are a workaround for botched tests caused by the pie
	# options used in gcc compilation.
	make -k \
		CFLAGS="-g -O2 -no-pie -fno-PIC" \
		CXXFLAGS="-g -O2 -no-pie -fno-PIC" \
		CFLAGS_FOR_TARGET="-g -O2" \
		CXXFLAGS_FOR_TARGET="-g -O2" \
		LDFLAGS= \
		check \
	|| err=1
	
	if [ $err -ne 0 ]; then
		logprint "Testing failed."
		grep -nl '^FAIL:' $(find -name '*.log')
		# TODO Fix open file limit issues w/ Chroot bootstrap:
		# there is an issue where using chroot to execute the kickoff is causing 
		# open file limits to be reset.  until that is resolved, these tests
		# will return a non-zero exit code.
		# this will need resolved before a production release.
		#assert_zero $err
	fi

	logprint "Build operation complete."
}


mode_install_pass1() {
	logprint "Starting install of ${APPNAME}..."
	pushd "${T_SOURCE_DIR}/build"
	assert_zero $?
	
	make install
	assert_zero $?
	
	logprint "Install operation complete."
}

mode_install_pass2() {
	logprint "Starting install of ${APPNAME}..."
	pushd "${T_SOURCE_DIR}/build"
	assert_zero $?
	
	make DESTDIR=${T_SYSROOT} install
	assert_zero $?
	
	# doublecheck this
	logprint "Clean up items..."
	rm -v ${T_SYSROOT}/usr/lib/lib{bfd,ctf,ctf-nobfd,opcodes}.{a,la}
	assert_zero $?
	
	rm -v rm -fv /usr/share/man/man1/{gprofng,gp-*}.1
	assert_zero $?
	
	logprint "Install operation complete."
}

mode_install_pass3() {
	logprint "Starting install of ${APPNAME}..."
	pushd "${T_SOURCE_DIR}/build"
	assert_zero $?
		
	make tooldir=/usr install
	assert_zero $?
	
	logprint "Cleaning up..."
	rm -fv /usr/lib/lib{bfd,ctf,ctf-nobfd,sframe,opcodes}.a
	assert_zero $?
	
	rm -fv /usr/share/man/man1/{gprofng,gp-*}.1
	assert_zero $?
	
	
	logprint "Install operation complete."
}


mode_help() {
	echo "${APPNAME} [ --stage ] [ --build_pass1 ] [ --install_pass1 ] [ --pass1 ] [ --build_pass2 ] [ --install_pass2 ] [ --pass2 ][ --build_pass3 ] [ --install_pass3 ] [ --pass3 ][ --help ]"
	exit 1
}

# MODE_PASS1 is a meta toggle for all pass1 modes.  Modes will always 
# run in the correct order.
if [ "$MODE_PASS1" = "true" ]; then
	MODE_STAGE=true
	MODE_BUILD_PASS1=true
	MODE_INSTALL_PASS1=true
fi

if [ "$MODE_PASS2" = "true" ]; then
	MODE_STAGE=true
	MODE_BUILD_PASS2=true
	MODE_INSTALL_PASS2=true
fi

if [ "$MODE_PASS3" = "true" ]; then
	MODE_STAGE=true
	MODE_BUILD_PASS3=true
	MODE_INSTALL_PASS3=true
fi

# if no options were selected, then show help and exit
if \
	[ "$MODE_HELP" != "true" ] && \
	[ "$MODE_STAGE" != "true" ] && \
	[ "$MODE_BUILD_PASS1" != "true" ] && \
	[ "$MODE_INSTALL_PASS1" != "true" ] && \
	[ "$MODE_BUILD_PASS2" != "true" ] && \
	[ "$MODE_INSTALL_PASS2" != "true" ] && \
	[ "$MODE_BUILD_PASS3" != "true" ] && \
	[ "$MODE_INSTALL_PASS3" != "true" ]
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

if [ "$MODE_BUILD_PASS2" = "true" ]; then
	logprint "Build of PASS2 selected."
	mode_build_pass2
	assert_zero $?
fi

if [ "$MODE_INSTALL_PASS2" = "true" ]; then
	logprint "Install of PASS2 selected."
	mode_install_pass2
	assert_zero $?
fi

if [ "$MODE_BUILD_PASS3" = "true" ]; then
	logprint "Build of PASS3 selected."
	mode_build_pass3
	assert_zero $?
fi

if [ "$MODE_INSTALL_PASS3" = "true" ]; then
	logprint "Install of PASS3 selected."
	mode_install_pass3
	assert_zero $?
fi

logprint "Execution of ${APPNAME} completed."
