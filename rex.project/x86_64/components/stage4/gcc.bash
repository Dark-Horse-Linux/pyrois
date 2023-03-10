#!/bin/bash
# desc:
# stages, builds, installs

# make variables persist in subprocesses for logging function
set -a

# ----------------------------------------------------------------------
# Configuration:
# ----------------------------------------------------------------------
# the name of this application
APPNAME="gcc"

# the version of this application
VERSION="12.2.0"

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
	logprint "Starting build of ${APPNAME}..."
	
	logprint "Entering build dir."	
	pushd "${T_SOURCE_DIR}"
	assert_zero $?
		
	# how many times do you need to compile this until you can use your fucking system?	
	logprint "GCC PASS 3 PREWORK"
		# patches
	logprint "Applying patches..."
	patch -p0 < "${PATCHES_DIR}/gcc_libarchpath_fhs.patch"
	assert_zero $?
	
	mkdir -v build
	pushd build

	logprint "Configuring ${APPNAME}..."
	../configure \
		--prefix=/usr \
		--enable-languages=c,c++ \
		--enable-default-pie \
		--enable-default-ssp \
		--disable-multilib \
		--disable-bootstrap \
		--with-system-zlib

	assert_zero $?
	
	logprint "Compiling..."
	make
	assert_zero $?

	# TODO this needs rewritten later to configure and compile as test user
	# and then test as that user, and then make install as root
	
	logprint "Testing"
	make -k check
	logprint "Checks exited with '$?'. "

	logprint "Test results:"
	cat ../contrib/test_summary
	

	logprint "Build operation complete."
}

mode_install() {
	logprint "Starting install of ${APPNAME}..."
	pushd "${T_SOURCE_DIR}/build"
	assert_zero $?
	
	logprint "Installing..."
	make install
	assert_zero $?
	
	# https://refspecs.linuxfoundation.org/FHS_3.0/fhs/ch03s09.html
	logprint "Creating FHS symlink from /usr/bin/cpp -> /usr/lib"
	# this is the C preprocessor, see ref 12 on Ch 3 ss 9 of FHS3
	ln -svr /usr/bin/cpp /usr/lib
	assert_zero $?
	
	logprint "Creating LTO compatibility symlink..."
	ln -sfv ../../libexec/gcc/$(gcc -dumpmachine)/${VERSION}/liblto_plugin.so /usr/lib/bfd-plugins/
	assert_zero $?
	
	logprint "Checking compilation..."

	logprint "Creating dummy.c"
	echo 'int main(){}' > dummy.c
	assert_zero $?

	logprint "Compiling dummy.c with CC"
	cc dummy.c -v -Wl,--verbose &> dummy.log
	assert_zero $?

	logprint "Dumping readelf output of resulting binary:"
	readelf -l a.out | grep ': /lib'	| grep "interpreter"
	assert_zero $?
	
	logprint "Dumping the compilation log:"
	# look for {Scrt1.o,crti.o,crtn.o}
	# verify the correct header files
	# check that the new linker is being used
	logprint "look for crt.o's:"
	cat dummy.log | grep "succeeded"
	assert_zero $?
	
	logprint "look at include paths:"
	grep -B4 '^ /usr/include' dummy.log
	assert_zero $?

	logprint "check linker search paths:"
	grep 'SEARCH.*/usr/lib' dummy.log |sed 's|; |\n|g'
	assert_zero $?
	
	logprint "Check glibc version:"
	grep "/lib.*/libc.so.6 " dummy.log
	assert_zero $?
	
	logprint "Check that the correct dynamic linker is being used:"
	grep found dummy.log
	assert_zero $?
	
	logprint "Cleaning up...."
	rm -v dummy.c a.out dummy.log
	assert_zero $?
	
	mkdir -pv /usr/share/gdb/auto-load/usr/lib
	assert_zero $?
	
	mv -v /usr/lib/*gdb.py /usr/share/gdb/auto-load/usr/lib
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
