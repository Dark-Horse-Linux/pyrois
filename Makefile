.EXPORT_ALL_VARIABLES:
.DEFAULT_GOAL := all
SHELL := /bin/bash

# circular dependency loading
ifndef project_root

%:
	. ./project_config.sh $(MAKE) $@

else 

#download_patches:
#	${make_dir}/download_patches.sh


#verify_patches:
#	${make_dir}/verify_patches.sh

# create the directory structures necessary to run the make
dirs:
	${dir_make}/dirs.sh

# installs the latest version of rex
install_rex:
	${dir_make}/install_rex.sh

download_sources:
	${dir_make}/download_sources.sh

build_stage1:
	sudo /usr/bin/env -i bash -c ". ./project_config.sh && ${dir_make}/build_stage1.sh"


# end dependency loading block
endif
