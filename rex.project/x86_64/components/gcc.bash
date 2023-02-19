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
MPFR_V="4.2.0"
GMP_V="6.2.1"
MPC_V="1.3.1"
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
    "build_gcc_pass1"
    "install_gcc_pass1"
    "build_gcc_pass2"
    "install_gcc_pass2"
    "build_libstdcxx_pass1"
    "install_libstdcxx_pass1"
    "build_libstdcxx_pass2"
    "install_libstdcxx_pass2"
    "gcc_pass1"
    "gcc_pass2"
    "libstdcxx_pass1"
    "libstdcxx_pass2"
    "help"
)

mode_help() {
	echo "${APPNAME} [ --stage ] [ --build_gcc_pass1 ] [ --install_gcc_pass1 ] [ --build_gcc_pass2 ] [ --install_gcc_pass2 ] [ --build_libstdcxx_pass1 ] [ --install_libstdcxx_pass1 ] [ --build_libstdcxx_pass2 ] [ --install_libstdcxx_pass2 ] [ --gcc_pass1 ] [ --gcc_pass2 ] [ --libstdcxx_pass1 ] [ --libstdcxx_pass2 ] [ --help ]"
	exit 0
}

# modes to associate with switches
# assumes you want nothing done unless you ask for it.
MODE_STAGE=false
MODE_BUILD_GCC_PASS1=false
MODE_INSTALL_GCC_PASS1=false
MODE_BUILD_GCC_PASS2=false
MODE_INSTALL_GCC_PASS2=false
MODE_BUILD_LIBSTDCXX_PASS1=false
MODE_INSTALL_LIBSTDCXX_PASS1=false
MODE_BUILD_LIBSTDCXX_PASS2=false
MODE_INSTALL_LIBSTDCXX_PASS2=false
MODE_LIBSTDCXX_PASS1=false
MODE_LIBSTDCXX_PASS2=false
MODE_GCC_PASS1=false
MODE_GCC_PASS2=false
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
        --build_gcc_pass1)
            MODE_BUILD_GCC_PASS1=true
            shift 1
            ;;
        --install_gcc_pass1)
            MODE_INSTALL_GCC_PASS1=true
            shift 1
            ;;
        --build_gcc_pass2)
            MODE_BUILD_GCC_PASS2=true
            shift 1
            ;;
        --install_gcc_pass2)
            MODE_INSTALL_GCC_PASS2=true
            shift 1
            ;;
        --build_libstdcxx_pass1)
            MODE_BUILD_LIBSTDCXX_PASS1=true
            shift 1
            ;;
        --install_libstdcxx_pass1)
            MODE_INSTALL_LIBSTDCXX_PASS1=true
            shift 1
            ;;
        --build_libstdcxx_pass2)
            MODE_BUILD_LIBSTDCXX_PASS2=true
            shift 1
            ;;
        --install_libstdcxx_pass2)
            MODE_INSTALL_LIBSTDCXX_PASS2=true
            shift 1
            ;;
        --gcc_pass1)
            MODE_GCC_PASS1=true
            shift 1
            ;;
        --gcc_pass2)
            MODE_GCC_PASS2=true
            shift 1
            ;;
        --libstdcxx_pass1)
            MODE_LIBSTDCXX_PASS1=true
            shift 1
            ;;
        --libstdcxx_pass2)
            MODE_LIBSTDCXX_PASS2=true
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
	

	pushd ${T_SOURCE_DIR}
	assert_zero $?

	# MPFR
	logprint "Extracting MPFR"
	tar xf "${SOURCES_DIR}/mpfr-${MPFR_V}.tar.xz" -C "${T_SOURCE_DIR}"
	assert_zero $?
	
	logprint "Staging MPFR"
	mv "${T_SOURCE_DIR}/mpfr-"* "${T_SOURCE_DIR}/mpfr"
	assert_zero $?

	# GMP
	logprint "Extracting GMP"
	tar xf "${SOURCES_DIR}/gmp-${GMP_V}.tar.xz" -C "${T_SOURCE_DIR}"
	assert_zero $?
	
	logprint "Staging GMP"
	mv "${T_SOURCE_DIR}/gmp-"* "${T_SOURCE_DIR}/gmp"
	assert_zero $?

	# MPC
	logprint "Extracting MPC"
	tar xf "${SOURCES_DIR}/mpc-${MPC_V}.tar.gz" -C "${T_SOURCE_DIR}"
	assert_zero $?
	
	logprint "Staging MPC"
	mv "${T_SOURCE_DIR}/mpc-"* "${T_SOURCE_DIR}/mpc"
	assert_zero $?


	logprint "Staging operation complete."
}

mode_build_libstdcxx_pass1() {
	logprint "Starting build of LIBSTDC++/pass1..."
	
	logprint "Entering build dir."	
	pushd "${T_SOURCE_DIR}"
	assert_zero $?
	
	mkdir -p build
	pushd build
	assert_zero $?
	
	logprint "Configuring libstdc++..."
	# Note: This currently depends on crosstools being in the top level dir of the T_SYSROOT
	# use a substring in the future
	../libstdc++-v3/configure \
		--host=${T_TRIPLET} \
		--build=$(../config.guess) \
		--prefix=/usr \
		--disable-multilib \
		--disable-nls \
		--disable-libstdcxx-pch \
		--with-gxx-include-dir=/$(basename ${CROSSTOOLS_DIR})/${T_TRIPLET}/include/c++/10.2.0
	assert_zero $?
	
	logprint "Compiling..."
	make
	assert_zero $?

	logprint "Build operation complete."
}

mode_build_libstdcxx_pass2() {
# this is meant to be kicked off from the chroot context.  do not expect
# this to work at all with a direct execution context from outside of the chroot.

	logprint "Starting build of LIBSTDC++/pass2..."
	
	logprint "Entering build dir."	
	pushd "${T_SOURCE_DIR}"
	assert_zero $?
	
	ln -s gthr-posix.h libgcc/gthr-default.h
	assert_zero $?
	
	mkdir -p build
	pushd build
	assert_zero $?
	
	logprint "Configuring libstdc++..."
	# Note: This currently depends on crosstools being in the top level dir of the T_SYSROOT
	# use a substring in the future
	../libstdc++-v3/configure \
		CXXFLAGS="-g -O2 -D_GNU_SOURCE" \
		--prefix=/usr \
		--disable-multilib \
		--disable-nls \
		--host=${T_TRIPLET} \
		--disable-libstdcxx-pch
	assert_zero $?
	
	logprint "Compiling..."
	make
	assert_zero $?

	logprint "Build operation complete."
}

mode_install_libstdcxx_pass1() {
	logprint "Starting install of LIBSTDC++/pass1..."
	
	pushd "${T_SOURCE_DIR}/build"
	assert_zero $?
	
	make DESTDIR=${T_SYSROOT} install
	assert_zero $?
	
	logprint "Install of libstdcxx complete."
}

mode_install_libstdcxx_pass2() {
	logprint "Starting install of LIBSTDC++/pass1..."
	
	pushd "${T_SOURCE_DIR}/build"
	assert_zero $?
	
	make install
	assert_zero $?
	
	logprint "Install of libstdcxx complete."
}

# when the build_pass1 mode is enabled, this will execute
mode_build_gcc_pass1() {
	logprint "Starting build of ${APPNAME}/pass1..."
	
	logprint "Entering build dir."	
	pushd "${T_SOURCE_DIR}"
	assert_zero $?
	
	# patches
	logprint "Applying patches..."
	patch -p0 < "${PATCHES_DIR}/gcc_libarchpath_fhs.patch"
	assert_zero $?
	
	mkdir -p build
	pushd build
	assert_zero $?
	
	logprint "Configuring ${APPNAME}..."
	../configure \
		--target=${T_TRIPLET} \
		--prefix=${CROSSTOOLS_DIR} \
		--with-glibc-version=2.37 \
		--with-sysroot=${T_SYSROOT} \
		--with-newlib \
		--without-headers \
		--enable-default-pie \
		--enable-default-ssp \
		--disable-nls \
		--disable-shared \
		--disable-multilib \
		--disable-threads \
		--disable-libatomic \
		--disable-libgomp \
		--disable-libquadmath \
		--disable-libssp \
		--disable-libvtv \
		--disable-libstdcxx \
		--enable-languages=c,c++
	assert_zero $?
	
	logprint "Compiling..."
	make
	assert_zero $?

	logprint "Build operation complete."
}

mode_build_gcc_pass2() {
	logprint "Starting build of ${APPNAME}/pass2..."
	
	logprint "Entering build dir."	
	pushd "${T_SOURCE_DIR}"
	assert_zero $?
	
	# patches
	logprint "Applying patches..."
	patch -p0 < "${PATCHES_DIR}/gcc_libarchpath_fhs.patch"
	assert_zero $?
	
	logprint "Entering build subdirectory"
	mkdir -p build
	pushd build
	assert_zero $?
	
	logprint "Creating posix thread support compatibility symlink..."
	mkdir -pv ${T_TRIPLET}/libgcc
	assert_zero $?
	
	ln -s ../../../libgcc/gthr-posix.h ${T_TRIPLET}/libgcc/gthr-default.h
	assert_zero $?
	
	logprint "Configuring ${APPNAME}..."
	../configure \
		--build=$(../config.guess) \
		--host=${T_TRIPLET} \
		--prefix=/usr \
		CC_FOR_TARGET=${T_TRIPLET}-gcc \
		--with-build-sysroot=${T_SYSROOT} \
		--enable-initfini-array \
		--disable-nls \
		--disable-multilib \
		--disable-decimal-float \
		--disable-libatomic \
		--disable-libgomp \
		--disable-libquadmath \
		--disable-libssp \
		--disable-libvtv \
		--disable-libstdcxx \
		--enable-languages=c,c++
	assert_zero $?
	
	logprint "Compiling..."
	make
	assert_zero $?

	logprint "Build operation complete."
}

mode_install_gcc_pass2() {
	logprint "Starting install of ${APPNAME}/pass2..."
	pushd "${T_SOURCE_DIR}/build"
	assert_zero $?
	
	make -j1 DESTDIR=${T_SYSROOT} install
	assert_zero $?
	
	
	logprint "Clean up items..."
	logprint "CC/GCC utility symlink"
	ln -sv gcc ${T_SYSROOT}/usr/bin/cc
	assert_zero $?

	logprint "Install operation complete."
	
}

mode_install_gcc_pass1() {
	logprint "Starting install of ${APPNAME}/pass1..."
	pushd "${T_SOURCE_DIR}/build"
	assert_zero $?
	
	make install
	assert_zero $?
	
	logprint "Install operation complete."
	
	logprint "Wrapping up headers..."
	popd
	pushd "${T_SOURCE_DIR}"
	assert_zero $?
	
	cat gcc/limitx.h gcc/glimits.h gcc/limity.h > `dirname $(${T_TRIPLET}-gcc -print-libgcc-file-name)`/install-tools/include/limits.h
	assert_zero $?
}
# MODE_GCC_PASS1 is a meta toggle for all pass1 modes.  Modes will always 
# run in the correct order.
if [ "$MODE_GCC_PASS1" = "true" ]; then
	echo "PASS1 selected"
	logprint "PASS1 selected."
	MODE_STAGE=true
	MODE_BUILD_GCC_PASS1=true
	MODE_INSTALL_GCC_PASS1=true
fi

if [ "$MODE_GCC_PASS2" = "true" ]; then
	logprint "PASS2 selected."
	MODE_STAGE=true
	MODE_BUILD_GCC_PASS2=true
	MODE_INSTALL_GCC_PASS2=true
fi

if [ "$MODE_LIBSTDCXX_PASS1" = "true" ]; then
	logprint "LIBSTDCXX PASS1 selected."
	MODE_BUILD_LIBSTDCXX_PASS1=true
	MODE_INSTALL_LIBSTDCXX_PASS1=true
fi

if [ "$MODE_LIBSTDCXX_PASS2" = "true" ]; then
	logprint "LIBSTDCXX PASS2 selected."
	MODE_STAGE=true
	MODE_BUILD_LIBSTDCXX_PASS2=true
	MODE_INSTALL_LIBSTDCXX_PASS2=true
fi

# if no options were selected, then show help and exit
if \
	[ "$MODE_HELP" != "true" ] && \
	[ "$MODE_STAGE" != "true" ] && \
	[ "$MODE_BUILD_GCC_PASS1" != "true" ] && \
	[ "$MODE_INSTALL_GCC_PASS1" != "true" ] && \
	[ "$MODE_BUILD_GCC_PASS2" != "true" ] && \
	[ "$MODE_INSTALL_PASS2" != "true" ] && \
	[ "$MODE_BUILD_LIBSTDCXX_PASS1" != "true" ] && \
	[ "$MODE_INSTALL_LIBSTDCXX_PASS1" != "true" ] && \
	[ "$MODE_BUILD_LIBSTDCXX_PASS2" != "true" ] && \
	[ "$MODE_INSTALL_LIBSTDCXX_PASS2" != "true" ]
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

if [ "$MODE_BUILD_GCC_PASS1" = "true" ]; then
	logprint "Build of PASS1 selected."
	mode_build_gcc_pass1
	assert_zero $?
fi

if [ "$MODE_INSTALL_GCC_PASS1" = "true" ]; then
	logprint "Install of PASS1 selected."
	mode_install_gcc_pass1
	assert_zero $?
fi

if [ "$MODE_BUILD_GCC_PASS2" = "true" ]; then
	logprint "Build of PASS2 selected."
	mode_build_gcc_pass2
	assert_zero $?
fi

if [ "$MODE_INSTALL_GCC_PASS2" = "true" ]; then
	logprint "Install of PASS2 selected."
	mode_install_gcc_pass2
	assert_zero $?
fi

if [ "$MODE_BUILD_LIBSTDCXX_PASS1" = "true" ]; then
	logprint "Build of LIBSTDC++ selected."
	mode_build_libstdcxx_pass1
	assert_zero $?
fi

if [ "$MODE_INSTALL_LIBSTDCXX_PASS1" = "true" ]; then
	logprint "INSTALL of LIBSTDC++ selected."
	mode_install_libstdcxx_pass1
	assert_zero $?
fi

if [ "$MODE_BUILD_LIBSTDCXX_PASS2" = "true" ]; then
	logprint "Build of LIBSTDC++ selected."
	mode_build_libstdcxx_pass2
	assert_zero $?
fi

if [ "$MODE_INSTALL_LIBSTDCXX_PASS2" = "true" ]; then
	logprint "INSTALL of LIBSTDC++ selected."
	mode_install_libstdcxx_pass2
	assert_zero $?
fi

logprint "Execution of ${APPNAME} completed."
