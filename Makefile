.EXPORT_ALL_VARIABLES:
.DEFAULT_GOAL := all
SHELL := /bin/bash

##
# Load the config file
##
# circular dependency loading
ifndef project_root

%:
	. ./project_config.sh $(MAKE) $@

else 

##
# Target Definitions
##
prepare_environment:
	sudo --preserve-env ${make_dir}/prepare_environment.sh

# download the new source directory contents like LFS proper
download_sources:
	${make_dir}/download_sources.sh

# download the patches from LFS
# there is no clean here because i bundle fixed patches
download_patches:
	${make_dir}/download_patches.sh

# verify the sources downloaded are intact
verify_sources:
	${make_dir}/verify_sources.sh

# verify the patches downloaded are intact
verify_patches:
	${make_dir}/verify_patches.sh

# builds a chroot
# don't preserve env on execution of these, it hits the ARG_MAX limit in the kernel/limits.h
build_stage1:
	sudo /usr/bin/env -i bash -c ". ./project_config.sh && ${make_dir}/build_stage1.sh"

# compiles temporary toolchain for new cross-compiler 
build_stage2:
	sudo /usr/bin/env -i bash -c ". ./project_config.sh && ${make_dir}/build_stage2.sh"

# populates basic sysroot as a chroot
build_stage3:
	sudo /usr/bin/env -i bash -c ". ./project_config.sh && ${make_dir}/build_stage3.sh"

# builds the rest of the system from inside the chroot
build_stage4:
	sudo /usr/bin/env -i bash -c ". ./project_config.sh && ${make_dir}/build_stage4.sh"


# works around apparently some kind of nesting bug w/ Rex and file descriptors
#hotfix_chroot_compiler:
#	@sudo --preserve-env ${rex_dir}/components/x86_64/stage_1/libstdcxx_pass2.bash ${workspace}


all:  build_stage1 hotfix_chroot_compiler build_stage2 
	
# enter the chroot after a stage1 build so we can play around 
enter_chroot:
	@sudo --preserve-env ${make_dir}/enter_chroot.sh ${workspace}

# clean up artifacts between builds if desired
clean:
	sudo --preserve-env ${make_dir}/clean.sh $(shell whoami)

# wipe the source directory	
clean_sources:
	sudo --preserve-env ${make_dir}/clean_sources.sh $(shell whoami)

# wipe the patches directory
clean_patches:
	sudo --preserve-env ${make_dir}/clean_patches.sh $(shell whoami)

download_rex:
	${make_dir}/download_rex.sh 
	
compile_rex:
	${make_dir}/compile_rex.sh
	
clean_logs:
	${make_dir}/clean_logs.sh
	
distclean: clean clean_sources clean_patches

make help:
	${make_dir}/help.sh

#instructions
# 01. make distclean
# 02. make download_rex
# 03. make compile_rex
# 04. make download_sources
# 05. make verify_sources
# 06. make download_patches
# 07. make verify_patches
# 08. make prepare_environment
# 09. make build_stage1
# 10. make hotfix_chroot_compiler
# 11. make build_stage2
# 12. make build_stage3

# Stage 1 builds a cross-compiler and temporary tools.
# Stage 2 uses that cross-compiler to build a chroot.
# Stage 3 starts building the system from inside the chroot.
# End conditional block.
# Ubuntu LTS deps:
#	git
#	make
#	cmake
#	g++
endif
