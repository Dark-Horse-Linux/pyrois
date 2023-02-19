#!/usr/bin/env bash

mkdir -pv ${dir_sysroot}/{etc,var} ${dir_sysroot}/usr/{bin,lib,sbin} || echofail "Creating sysroot directories..."

for i in bin lib sbin; do
  ln -sv usr/$i ${dir_sysroot}/$i || echofail "Creating sysroot symlinks for bin,lib,sbin"
done

case $(uname -m) in
  x86_64) 
	mkdir -pv ${dir_sysroot}/lib64 || echofail "Creating /lib64"
	;;
esac

mkdir -v ${TEMP_STAGE_DIR} || echofail "Creating ${TEMP_STAGE_DIR}"
