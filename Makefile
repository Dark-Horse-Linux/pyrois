.EXPORT_ALL_VARIABLES:
.DEFAULT_GOAL := all
SHELL := /bin/bash

# circular dependency loading
ifndef project_root

%:
	. ./project_config.sh $(MAKE) $@

else 


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

# example:
# make dirs
# make install_rex
# make download_sources
# make download_patches
# make build_stage1

# end dependency loading block
endif
