#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
TOOL_CHAIN_SYSROOT_PATH=/home/milosmarinkovic/arm-cross-compiler/arm-gnu-toolchain-13.3.rel1-x86_64-aarch64-none-linux-gnu/aarch64-none-linux-gnu/libc/
KERNEL_VERSION=v5.15.163
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=/home/milosmarinkovic/embedded-linux-course/assignment-1-YoNoSoyMarinero/finder-app
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-

if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p ${OUTDIR}

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}
	
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} mrproper
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig
    make -j4 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} all
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} modules
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} dtbs
fi

if [ ! -e ${OUTDIR}/Image ]; then
	echo "Adding the Image in outdir"
	cp ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ${OUTDIR} 
fi

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi

if [ ! -d "$OUTDIR/rootfs" ]; then

	mkdir "${OUTDIR}/rootfs" && cd "${OUTDIR}/rootfs"
	mkdir -p bin dev etc home lib lib64 proc sbin sys tmp usr var
	mkdir -p usr/bin usr/lib usr/sbin
	mkdir -p var/log
fi

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
else
    cd busybox
fi

make distclean
make defconfig
make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
make CONFIG_PREFIX=${OUTDIR}/rootfs ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} install


cd "$OUTDIR/rootfs"

echo "Library dependencies"
${CROSS_COMPILE}readelf -a bin/busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a bin/busybox | grep "Shared library"


cp "${TOOL_CHAIN_SYSROOT_PATH}/lib/ld-linux-aarch64.so.1" \
	"${TOOL_CHAIN_SYSROOT_PATH}/lib64/libm.so.6" \
	"${TOOL_CHAIN_SYSROOT_PATH}/lib64/libresolv.so.2" \
	"${TOOL_CHAIN_SYSROOT_PATH}/lib64/libc.so.6" \
	"${OUTDIR}/rootfs/lib64"

sudo mknod -m 666 dev/null c 1 3
sudo mknod -m 666 dev/console c 5 1

cd "${FINDER_APP_DIR}"

make clean
make CROSS_COMPILE=${CROSS_COMPILE}

cp "${FINDER_APP_DIR}/writer" \
   "${FINDER_APP_DIR}/finder-test.sh" \
   "${FINDER_APP_DIR}/finder.sh" \
   "${FINDER_APP_DIR}/autorun-qemu.sh" \
   "${OUTDIR}/rootfs/home"

cp -r "${FINDER_APP_DIR}/conf" "${OUTDIR}/rootfs/home"


cd "${OUTDIR}/rootfs"

find . | cpio -H newc -ov --owner root:root > ${OUTDIR}/initramfs.cpio

gzip -f "${OUTDIR}/initramfs.cpio"
