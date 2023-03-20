.EXPORT_ALL_VARIABLES:
.DEFAULT_GOAL := all
SHELL := /bin/bash

# circular dependency loading
ifndef project_root

%:
	. ./project_config.sh $(MAKE) $@

else 


clean_unsafe:
	set -e
	sudo /usr/bin/env -i bash -c ". ./project_config.sh && ${dir_make}/clean.sh"

clean:
	set -e
	make disarm_chroot 
	make clean_unsafe

# same as clean, but retain logs
purge_artifacts:
	set -e
	${dir_make}/purge_artifacts.sh


# these need run in the following order:
dirs:
	set -e
	${dir_make}/dirs.sh

# installs the latest version of rex from master branch
# will later be tied to a release tag
install_rex:
	set -e
	${dir_make}/install_rex.sh

# installs the versions designed for this run
download_sources:
	set -e
	${dir_make}/download_sources.sh

# ""
download_patches:
	set -e
	${dir_make}/download_patches.sh

# kicks off rex
build_stage1:
	set -e
	sudo /usr/bin/env -i bash -c ". ./project_config.sh && ${dir_make}/build_stage1.sh"

# kicks off rex
build_stage2:
	set -e
	sudo /usr/bin/env -i bash -c ". ./project_config.sh && ${dir_make}/build_stage2.sh"

arm_chroot:
	set -e
	sudo /usr/bin/env -i bash -c ". ./project_config.sh && ${dir_make}/arm_chroot.sh"

disarm_chroot:
	set -e
	sudo /usr/bin/env -i bash -c ". ./project_config.sh && ${dir_make}/disarm_chroot.sh"

# do not enter the chroot like this unless you have run arm_chroot.  
# build_stage2 does this automatically.
enter_chroot:
	set -e
	sudo /usr/bin/env -i bash -c ". ./project_config.sh && ${dir_make}/enter_chroot.sh"

#embeds and kicks off rex from inside chroot
build_stage3:
	set -e
	sudo /usr/bin/env -i bash -c ". ./project_config.sh && ${dir_make}/build_stage3.sh"

# offers to back up
backup:
	set -e
	sudo /usr/bin/env -i bash -c ". ./project_config.sh && ${dir_make}/backup_create.sh"

restore_backup:
	set -e
	sudo bash -c ". ./project_config.sh && ${dir_make}/backup_restore.sh"

build_stage4:
	set -e
	sudo /usr/bin/env -i bash -c ". ./project_config.sh && ${dir_make}/build_stage4.sh"

build_stage5:
	set -e
	sudo /usr/bin/env -i bash -c ". ./project_config.sh && ${dir_make}/build_stage5.sh"

master:
	set -e
	sudo /usr/bin/env -i bash -c ". ./project_config.sh && ${dir_make}/master.sh"

# example:
# 	make dirs
# 	make install_rex
# 	make download_sources
# 	make download_patches
# 	make build_stage1
# 	make build_stage2
# 	optional: make enter_chroot
# 	make build_stage3
# 	optional: make build_stage4backup
# 	make build_stage4

.ONESHELL:
all:
	set -e; \
	make disarm_chroot && \
	make clean && \
	make dirs && \
	make install_rex && \
	make download_patches && \
	make download_sources && \
	make build_stage1 && \
	make build_stage2 && \
	make build_stage3 && \
	make backup && \
	make build_stage4 && \
	make build_stage5


# Remember, before you make clean or make purge_artifacts you MUST run
# make disarm_chroot beforehand or you could cause irreversible damage 
# to your system.  It is recommended that these operations only be 
# performed on a VM, and the host distribution is only tested on Fedora.

# end dependency loading block
endif
