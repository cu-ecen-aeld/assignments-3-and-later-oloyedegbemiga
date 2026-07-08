#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.15.163
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
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

    # TODO: Add your kernel build steps here
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig
    make -j"$(nproc)" ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} Image

    cp arch/${ARCH}/boot/Image "${OUTDIR}/Image"
fi
# cp arch/${ARCH}/boot/Image "${OUTDIR}/Image"

echo "Adding the Image in outdir"

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi

# TODO: Create necessary base directories
mkdir -p "${OUTDIR}/rootfs"

mkdir -p "${OUTDIR}/rootfs"/{bin,dev,etc,home,lib,lib64,proc,sbin,sys,tmp,usr,var}
mkdir -p "${OUTDIR}/rootfs"/usr/{bin,sbin}
mkdir -p "${OUTDIR}/rootfs/var/log"

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    # TODO:  Configure busybox
    make ARCH=${ARCH} CROSS_COMPLILE=${CROSS_COMPILE} distclean
    make ARCH=${ARCH} CROSS_COMPLILE=${CROSS_COMPILE} defconfig

else
    cd busybox
fi

# TODO: Make and install busybox

make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} distclean
make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig

sed -i 's/^CONFIG_TC=y/# CONFIG_TC is not set/' .config

yes "" | make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} oldconfig
make -j"$(nproc)" ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
make CONFIG_PREFIX="${OUTDIR}/rootfs" ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} install

make -j"$(nproc)" ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
make CONFIG_PREFIX=${OUTDIR}/rootfs ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} install

echo "Library dependencies"

${CROSS_COMPILE}readelf -a busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a busybox | grep "Shared library"

INTERPRETER="$(${CROSS_COMPILE}readelf -a busybox | sed -n 's/.*Requesting program from interpreter: \(.*\)/\1/p')"

# TODO: Add library dependencies to rootfs
# INTERPRETER="$(${CROSS_COMPILE}readelf -a bin/busybox | sed -n 's/.*Requesting program from interpreter: \(.*\)/\1/p')"
INTERPRETER="$(${CROSS_COMPILE}readelf -a busybox | sed -n 's/.*Requesting program interpreter: \(.*\)]/\1/p')"
SYSROOT="$(${CROSS_COMPILE}gcc -print-sysroot)"

if [ -n "${INTERPRETER}" ]
    then
        mkdir -p "${OUTDIR}/rootfs$(dirname "${INTERPRETER}")"
        cp -L "${SYSROOT}${INTERPRETER}" "${OUTDIR}/rootfs${INTERPRETER}"
    fi

for BIN in "${OUTDIR}/busybox/busybox" "${OUTDIR}/rootfs/home/writer"
do
    INTERPRETER="$(${CROSS_COMPILE}readelf -a "$BIN" | sed -n 's/.*Requesting program interpreter: \(.*\)]/\1/p')"

    if [ -n "${INTERPRETER}" ]; then
        mkdir -p "${OUTDIR}/rootfs$(dirname "${INTERPRETER}")"
        cp -L "${SYSROOT}${INTERPRETER}" "${OUTDIR}/rootfs${INTERPRETER}"
    fi

    for LIBRARY in $(${CROSS_COMPILE}readelf -d "$BIN" | sed -n 's/.*Shared library: \[\(.*\)\]/\1/p')
    do
        LIBRARY_PATH="$(find "${SYSROOT}" -name "${LIBRARY}" -print -quit)"
        mkdir -p "${OUTDIR}/rootfs$(dirname "${LIBRARY_PATH#"${SYSROOT}"}")"
        cp -L "${LIBRARY_PATH}" "${OUTDIR}/rootfs${LIBRARY_PATH#"${SYSROOT}"}"
    done
done


# TODO: Make device nodes
sudo mknod -m 666 "${OUTDIR}/rootfs/dev/null" c 1 3
sudo mknod -m 666 "${OUTDIR}/rootfs/dev/console" c 5 1

# TODO: Clean and build the writer utility
make -C "${FINDER_APP_DIR}" clean
make -C "${FINDER_APP_DIR}" CROSS_COMPILE="${CROSS_COMPILE}"


# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs

cp "${FINDER_APP_DIR}/finder.sh" "${OUTDIR}/rootfs/home/"
cp "${FINDER_APP_DIR}/writer" "${OUTDIR}/rootfs/home/"
cp "${FINDER_APP_DIR}/finder-test.sh" "${OUTDIR}/rootfs/home/"
cp "${FINDER_APP_DIR}/autorun-qemu.sh" "${OUTDIR}/rootfs/home/"


mkdir -p "${OUTDIR}/rootfs/home"
cp -rL "${FINDER_APP_DIR}/conf" "${OUTDIR}/rootfs/home/"
cp -rL "${FINDER_APP_DIR}/conf" "${OUTDIR}/rootfs/"


chmod +x "${OUTDIR}/rootfs/home/finder.sh"
chmod +x "${OUTDIR}/rootfs/home/finder-test.sh"
chmod +x "${OUTDIR}/rootfs/home/writer"
chmod +x "${OUTDIR}/rootfs/home/autorun-qemu.sh"



# TODO: Chown the root directory
sudo chown -R root:root "${OUTDIR}/rootfs"

# TODO: Create initramfs.cpio.gz
cd "${OUTDIR}/rootfs"
find . | cpio -H newc -ov --owner root:root > "${OUTDIR}/initramfs.cpio"
gzip -f "${OUTDIR}/initramfs.cpio"