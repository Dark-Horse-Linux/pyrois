#!/usr/bin/env bash

# closely aligns with LFS Ch 5, 6

# fix an issue with open files limit on some hosts
ulimit -l unlimited

#ulimit -n 10240 
ulimit -c unlimited

echo "Bootstrapping from MAKE to REX..."

# Executes rex from within the shell.

${dir_localtools}/rex -v \
	-c ${dir_rex}/x86_64/rex.config \
	-p ${dir_rex}/x86_64/plans/stage1.plan

retVal=$?
exit $retVal
