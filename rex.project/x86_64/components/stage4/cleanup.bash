#!/bin/bash
# desc:
# stages, builds, installs

# make variables persist in subprocesses for logging function
set -a

APPNAME="post-stage4-cleanup"


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

logprint "Cleanup of /tmp"
rm -rf /tmp/*
assert_zero $?

logprint "Erasing libtool archive files"
find /usr/lib /usr/libexec -name \*.la -delete
assert_zero $?

logprint "Deleting temporary toolchain..."
find /usr -depth -name ${T_TRIPLET}\* | xargs rm -vrf
assert_zero $?

# almost directly lifted from LFS
logprint "Stripping Debuginfo..."
save_usrlib="$(cd /usr/lib; ls ld-linux*[^g])
             libc.so.6
             libthread_db.so.1
             libquadmath.so.0.0.0
             libstdc++.so.6.0.30
             libitm.so.1.0.0
             libatomic.so.1.2.0"

pushd /usr/lib

for LIB in $save_usrlib; do
	logprint "Stripping LIB:\t$LIB"
	objcopy --only-keep-debug $LIB $LIB.dbg
	cp $LIB /tmp/$LIB
	assert_zero $?
	strip --strip-unneeded /tmp/$LIB
	assert_zero $?
	objcopy --add-gnu-debuglink=$LIB.dbg /tmp/$LIB
	assert_zero $?
	install -vm755 /tmp/$LIB /usr/lib
	assert_zero $?
done

online_usrbin="bash find strip"
online_usrlib="libbfd-2.40.so
               libsframe.so.0.0.0
               libhistory.so.8.2
               libncursesw.so.6.4
               libm.so.6
               libreadline.so.8.2
               libz.so.1.2.13
               $(cd /usr/lib; find libnss*.so* -type f)"

for BIN in $online_usrbin; do
	logprint "Stripping BIN:\t$BIN"
    cp /usr/bin/$BIN /tmp/$BIN
	assert_zero $?
    strip --strip-unneeded /tmp/$BIN
	assert_zero $?
    install -vm755 /tmp/$BIN /usr/bin
	assert_zero $?
done

LIB=""
for LIB in $online_usrlib; do
	logprint "Stripping LIB:\t$LIB"
	cp /usr/lib/$LIB /tmp/$LIB
   	assert_zero $?
	strip --strip-unneeded /tmp/$LIB
   	assert_zero $?
	install -vm755 /tmp/$LIB /usr/lib
   	assert_zero $?
done

for i in $(find /usr/lib -type f -name \*.so* ! -name \*dbg) \
         $(find /usr/lib -type f -name \*.a)                 \
         $(find /usr/{bin,sbin,libexec} -type f); do
    case "$online_usrbin $online_usrlib $save_usrlib" in
        *$(basename $i)* )
            ;;
        * ) strip --strip-unneeded $i
            ;;
    esac
done



echo; echo; echo
logprint "Cleaning /tmp/"
rm -Rf /tmp/*
assert_zero $?

logprint "Cleanup .la files..."
find /usr/lib /usr/libexec -name \*.la -delete
assert_zero $?

logprint "Removing temporary tools..."
find /usr -depth -name "${T_TRIPLET}*" -exec rm -rf {} \;
assert_zero $?

# TODO better integrate test user lifecycle

logprint "Execution of ${APPNAME} completed."
