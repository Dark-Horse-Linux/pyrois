#!/usr/bin/env bash

function echofail() {
	echo "FAILED: $1"
	exit 1
}

wget \
	-q \
	--show-progress \
	--continue \
	-R "index.html*" \
	-r \
	-np \
	-nH \
	--cut-dirs=2 \
	-P ${dir_sources} \
	--directory-prefix=${dir_sources} \
	https://storage.darkhorselinux.org/sources/upstream_sources/ \
	|| echofail "Downloading sources..."


echo "Validating source downloads..."
pushd ${dir_sources} 1>/dev/null 2>/dev/null

md5sum --quiet -c "md5sums.txt" || echofail "Validation failed.  Redownload."
err=$?
popd 1>/dev/null 2>/dev/null

echo "Finished with exit code $err"
