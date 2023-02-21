.EXPORT_ALL_VARIABLES:
.DEFAULT_GOAL := all
SHELL := /bin/bash

# circular dependency loading
ifndef project_root

%:
	. ./project_config.sh $(MAKE) $@

else 


clean:
	sudo /usr/bin/env -i bash -c ". ./project_config.sh && ${dir_make}/clean.sh"

# same as clean, but retain logs
purge_artifacts:
	${dir_make}/purge_artifacts.sh


# these need run in the following order:
dirs:
	${dir_make}/dirs.sh

# installs the latest version of rex from master branch
# will later be tied to a release tag
install_rex:
	${dir_make}/install_rex.sh

# installs the versions designed for this run
download_sources:
	${dir_make}/download_sources.sh

# ""
download_patches:
	${dir_make}/download_patches.sh

# kicks off rex
build_stage1:
	sudo /usr/bin/env -i bash -c ". ./project_config.sh && ${dir_make}/build_stage1.sh"

# kicks off rex
build_stage2:
	sudo /usr/bin/env -i bash -c ". ./project_config.sh && ${dir_make}/build_stage2.sh"

arm_chroot:
	sudo /usr/bin/env -i bash -c ". ./project_config.sh && ${dir_make}/arm_chroot.sh"

disarm_chroot:
	sudo /usr/bin/env -i bash -c ". ./project_config.sh && ${dir_make}/disarm_chroot.sh"

# do not enter the chroot like this unless you have run arm_chroot.  
# build_stage2 does this automatically.
enter_chroot:
	sudo /usr/bin/env -i bash -c ". ./project_config.sh && ${dir_make}/enter_chroot.sh"

#embeds and kicks off rex
build_stage3:
	sudo /usr/bin/env -i bash -c ". ./project_config.sh && ${dir_make}/build_stage3.sh"

# example:
# make dirs
# make install_rex
# make download_sources
# make download_patches
# make build_stage1
# make build_stage2
# optional: make enter_chroot
# make build_stage3

all: disarm_chroot clean dirs install_rex download_patches download_sources build_stage1 build_stage2 build_stage3

# Remember, before you make clean or make purge_artifacts you MUST run
# make disarm_chroot beforehand or you could cause irreversible damage 
# to your system.  It is recommended that these operations only be 
# performed on a VM, and the host distribution is only tested on Fedora.

# end dependency loading block
endif
