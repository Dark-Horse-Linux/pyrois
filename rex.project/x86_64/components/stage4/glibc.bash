#!/bin/bash
# desc:
# stages, builds, installs

# make variables persist in subprocesses for logging function
set -a

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
	logprint "Starting build of ${APPNAME}/pass1 of stage2..."
	
	logprint "Entering stage dir."	
	pushd "${T_SOURCE_DIR}"
	assert_zero $?
	
	logprint "Applying patches..."
	patch -Np1 -i ${PATCHES_DIR}/glibc-${VERSION}-fhs-1.patch
	assert_zero $?

	# TODO make this a patch
	sed '/width -=/s/workend - string/number_length/' -i stdio-common/vfprintf-process-arg.c
    assert_zero $?
	
	logprint "Entering temp build dir..."
	mkdir -p build
	pushd build
	assert_zero $?
	
	# TODO make this a patch
	echo "rootsbindir=/usr/sbin" > ${T_SOURCE_DIR}/build/configparms
	assert_zero $?
	
	logprint "Configuring ${APPNAME}..."
	../configure \
		--prefix=/usr \
		--disable-werror \
		--enable-kernel=3.2 \
		--enable-stack-protector=strong \
		--with-headers=/usr/include \
		libc_cv_slibdir=/usr/lib
	assert_zero $?
	
	logprint "Compiling..."
	make
	assert_zero $?
	
	logprint "Testing build..."
	make check
	
	logprint "Build operation complete."
}

mode_install() {
	logprint "Starting install of ${APPNAME}..."
	pushd "${T_SOURCE_DIR}/build"
	assert_zero $?

	logprint "Creating empty ld.so.conf"
	touch /etc/ld.so.conf
	assert_zero $?
	
	# TODO make this a patch
	logprint "Patching the makefile... :/"
	sed '/test-installation/s@$(PERL)@echo not running@' -i ../Makefile
	assert_zero $?
	
	logprint "Installing..."
	make install
	assert_zero $?
	
	logprint "Doing the ridiculous glibc post-install work..."

	logprint "Fixing hardcoded path to the executable loader in the ldd script"
	sed '/RTLDLIST=/s@/usr@@g' -i /usr/bin/ldd
	assert_zero $?
	
	logprint "Installing /etc/nscd.conf"
	cp -v ../nscd/nscd.conf /etc/nscd.conf
	assert_zero $?
	
	logprint "Creating /var/cache/nscd"
	mkdir -pv /var/cache/nscd
	
	logprint "Installing systemD support for nscd..."
	install -v -Dm644 ../nscd/nscd.tmpfiles /usr/lib/tmpfiles.d/nscd.conf
	assert_zero $?
	
	install -v -Dm644 ../nscd/nscd.service /usr/lib/systemd/system/nscd.service
	assert_zero $?
	
	mkdir -pv /usr/lib/locale
	assert_zero $?

	logprint "Installing locale definitions..."
	make localedata/install-locales
	assert_zero $?
	
	localedef -i POSIX -f UTF-8 C.UTF-8 2> /dev/null || true
	assert_zero $?
	
	logprint "Installing /etc/nsswitch.conf"
	cp -vf ${CONFIGS_DIR}/etc_nsswitch.conf /etc/nsswitch.conf
	assert_zero $?
	
	logprint "Installing tzdata which glibc should totally be remotely related to (not)..."
	mkdir -p tzdata
	pushd tzdata
	assert_zero $?
	
	tar -xvf ${SOURCES_DIR}/tzdata2022g.tar.gz -C ./ 
	ZI=/usr/share/zoneinfo
	mkdir -p ${ZI}/{posix,right}
	for TZ in etcetera southamerica northamerica europe africa antarctica asia australasia backward; do
		zic -L /dev/null -d ${ZI} ${TZ}
		zic -L /dev/null -d ${ZI}/posix ${TZ}
		zic -L leapseconds -d ${ZI}/right ${TZ}
	done

	cp -v zone.tab zone1970.tab iso3166.tab ${ZI}
	assert_zero $?
	
	# this will likely become part of the installer for TZ selection
	# NOTE: really should default to UTC until set by user at that point
	zic -d ${ZI} -p America/New_York
	assert_zero $?
	unset ${ZI}

	logprint "Setting timezone to UTC..."
	ln -sfv /usr/share/zoneinfo/UTC /etc/localtime
	assert_zero $?
	
	logprint "Installing /etc/ld.so.conf"
	cp -vf ${CONFIGS_DIR}/etc_ld.so.conf /etc/ld.so.conf
	assert_zero $?
	
	mkdir -pv /etc/ld.so.conf.d
	asset_zero $?
	
	cp -vf ${CONFIGS_DIR}/etc_ld.so.conf.d_usr-local-lib.conf /etc/ld.so.conf.d/user-local-lib.conf
	assert_zero $?
	
	cp -vf ${CONFIGS_DIR}/etc_ld.so.conf.d_opt-lib.conf /etc/ld.so.conf.d/opt-lib.conf
	assert_zero $?

	logprint "Glibc install operation complete.  Jesus-- we think?"
}


mode_help() {
	echo "${APPNAME} [ --stage ] [ --build ] [ --install ] [ --all ] [ --help ]"
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

