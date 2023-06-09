set -a

source ./project_config.sh

TERM=xterm-256color
COLORTERM=truecolor
LC_ALL=C

function echofail() {
	echo
	echo "FAILED: $1"
	echo
	exit 1
}

# keeps talking about T_SYSROOT as $LFS
# wants $LFS path to be a mount
# needs to be set for any user including root

#2.6
# sourced from project_config
T_SYSROOT=${dir_sysroot}
LFS=${T_SYSROOT}

# 4.3 we skip user and group creation, it's expected to be done before
# you start if you want a different user than you're running as
# == after that, configure the rex unit for dir creation to use that user

if [ "$(id -u)" -ne 0 ]; then 
	echo "Not running as root." 
fi

# 4.4

# The set +h command turns off bash's hash function, which affects caching of paths for executables
set +h

# ensures newly created files and directories are only writable by their owner, but are readable and executable by anyone
umask 022

# sets a comptabile machine name description for use when building crosstools that isn't going to be what the host system is using
# $LFS_TGT is what LFS uses for this
T_TRIPLET=x86_64-dhl-linux-gnu


# prevents some configure scripts from looking in the wrong place for config.site 
CONFIG_SITE=${T_SYSROOT}/usr/share/config.site

# 4.5
MAKEFLAGS="-j$(nproc)"

# where the cross-compiler gets installed ($LFS/tools)
CROSSTOOLS_DIR=${T_SYSROOT}/xtools
TEMP_STAGE_DIR=${T_SYSROOT}/source_stage
# from project_config
SOURCES_DIR=${dir_sources}
PATCHES_DIR=${dir_patches}
LOGS_ROOT=${dir_logs}/apps/stage1

# fail the unit in the event of a non-zero value passed
# used primarily to check exit codes on previous commands
# also a great convenient place to add in a "press any key to continue"
assert_zero() {
	if [[ "$1" -eq 0 ]]; then 
		return
	else
		exit $1
	fi
}

PATH=${CROSSTOOLS_DIR}/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin
