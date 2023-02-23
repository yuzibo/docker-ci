#!/bin/sh 

# It woule be good to test it outside of Docker
OUT_DIR="$1"

ROOTFS_IMG="nvme-rootfs.img"
NVME_ROOTFS_IMG="${OUT_DIR}/${ROOTFS_IMG}"
DISK_MB=4096

if [ -f ${NVME_ROOTFS_IMG} ]; then
    echo "deleting nvme rootfs image..."
    rm ${NVME_ROOTFS_IMG}
fi

dd if=/dev/zero of="${NVME_ROOTFS_IMG}" bs=1M count=4096

echo "Creating Blank Image ${NVME_ROOTFS_IMG}"

#truncate -s "${DISK_MB}M" "${NVME_ROOTFS_IMG}"


sgdisk -g --clear --set-alignment=1 \
       --new=1:34:-1   --change-name=1:'rootfs'        --typecode=1:0x0700 --attributes=3:set:2  \
       ${NVME_ROOTFS_IMG} 

#LOOPDEV=$(kpartx -av "${NVME_ROOTFS_IMG}")
#echo "print ${LOOPDEV}"
LOOPDEV=$(kpartx -av "${NVME_ROOTFS_IMG}"| awk '{print $3}')
echo "${LOOPDEV}"
#LOOP="$(losetup -f --partscan --show "${NVME_ROOTFS_IMG}")"
#echo "testing ${LOOP}" 
#LOOPDEV="${LOOP}"
echo "Partitioning loopback device ${LOOPDEV}"

#parted -s -a optimal -- "${LOOPDEV}" mkpart root ext4 300MiB -1GiB
echo "new parted..."


mkfs.ext4 -L rootfs -F "/dev/mapper/${LOOPDEV}"

# Copy Files, first the rootfs partition
echo "Mounting  partitions ${LOOPDEV}"
ROOTFS_POINT=/nvme_rootfs
mkdir -p "${ROOTFS_POINT}"


mount "/dev/mapper/${LOOPDEV}" "${ROOTFS_POINT}"

#mount ${LOOPDEV} /mnt
debootstrap --arch=riscv64 --keyring /usr/share/keyrings/debian-ports-archive-keyring.gpg --include=debian-ports-archive-keyring,ca-certificates  unstable ${ROOTFS_POINT} https://mirror.iscas.ac.cn/debian-ports

ls ${ROOTFS_POINT}
cp /usr/bin/qemu-riscv64-static ${ROOTFS_POINT}/usr/bin/
chroot "${MNTPOINT}" qemu-riscv64-static /bin/sh /builder/setup_rootfs.sh

umount "${ROOTFS_POINT}" 

kpartx -d ${NVME_ROOTFS_IMG}

