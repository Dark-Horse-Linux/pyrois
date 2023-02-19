function echofail() {
	echo $1
	exit 1
}

function mkfaildir() {
	echo "Creating directory '$1'."
	mkdir -p $1 || echofail "Failed to create '$1' directory."
}

# clean the slate
rm -Rfv ${dir_stage}
rm -Rf ${dir_logs}

mkfaildir ${dir_stage}
mkfaildir ${dir_localtools}
mkfaildir ${dir_artifacts}
mkfaildir ${dir_logs}
mkfaildir ${dir_configs}
mkfaildir ${dir_patches}
mkfaildir ${dir_sources}
mkfaildir ${dir_sysroot}

echo "Stage directories now exist."
