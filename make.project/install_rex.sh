#!/usr/bin/env bash

set -u

function echofail() {
	echo "Failed: $1"
	exit 1
}

echo "Downloading Rex Source code to '${dir_stage}/rex'."
git clone https://source.silogroup.org/SURRO-Linux/rex ${dir_stage}/rex || echofail "Cloning rex repo."

pushd ${dir_stage}/rex || echofail "Entering rex build dir"
cmake . || echofail "cmake/rex."
make || echofail "make/rex"
cp -v ./rex ${dir_localtools}/ || fail "Installing rex to '${dir_localtools}'."
dirs -c
