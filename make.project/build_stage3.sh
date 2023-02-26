#!/usr/bin/env bash

# fix an issue with open files limit on some hosts
ulimit -l unlimited

#ulimit -n 10240 
ulimit -c unlimited


# closely aligns with LFS Ch 5, 6
T_SYSROOT=${dir_sysroot}

project_root=/rex_embedded

echo "Bootstrapping from MAKE to REX..."
dir_rex=/rex_embedded/rex.project

# Executes rex from within the chroot.
/usr/sbin/chroot "${T_SYSROOT}" /usr/bin/env -i \
	HOME="/" \
	TERM="$TERM" \
	COLORTERM=$COLORTERM \
	PS1='\n(Dark Horse Linux) [ \u @ \H ] << \w >>\n\n[- ' \
	PATH=/usr/bin:/usr/sbin \
	project_root="${project_root}" \
	dir_rex="${dir_rex}" \
	dir_logs="/${project_root}/logs" \
	/rex_embedded/stage/rex/rex -v -c ${dir_rex}/x86_64/rex.config -p ${dir_rex}/x86_64/plans/stage3.plan
	

retVal=$?
echo "Rex exited with error code '$retVal'."
exit $retVal
