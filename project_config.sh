#!/bin/bash 
# project_config
# -
# This file sets some globals for the make project as well as for the 
# rest of the build process components.  It is assumed to be in the root
# of the project directory.

# set all vars to export automatically
set -a

echo "Loading project_config.sh...."

#
## Shared Variables
#

# this is where the directory for foster is located. serves as the 
# parent directory for most other directories
project_root="$(dirname $(readlink -f "${BASH_SOURCE[0]}"))"
# the project files for the make system that is used to orchestrate the 
# build steps
dir_make=${project_root}/make.project

# the stage directory.  this contains the mutable directory where 
# artifacts are created, as well as the directories which store
# configuration for cacheable items (like source code packages, patches,
# et al.)
dir_stage=${project_root}/stage

# local tools (rex is installed here)
dir_localtools=${dir_stage}/local

# the mutable directory.  Anything created by the build process should
# go here to prevent a myriad of issues.
dir_artifacts=${dir_stage}/artifacts

# path for the logs
dir_logs=${project_root}/logs

# config directory - general path for configuration files on the target
# system before they're placed, as well as various values for configure
# of the build
dir_configs=${dir_stage}/configs

# the patches directory.  this contains all the patches we use during
# the foster build
dir_patches=${dir_stage}/patches

# sources dir.  this path is the directory for where the sources go that
# get compiled for the initial chroot/sysroot
dir_sources=${dir_stage}/sources

# the rex project directory contains all the componennts used by the rex
# utility when it takes over compilation
dir_rex=${project_root}/rex.project

# the sysroot being created
dir_sysroot=${dir_artifacts}/T_SYSROOT

user="phanes"
group="phanes"

# if we're being supplied parameters we assume it's being called by make
# and need to recall make with all appropriate vars set
if [ -n "$1" ]; then
    # The first argument is set, call back into make.
    $1 $2
fi

# EOF
