
REGION=us-east-1
aws configure set default.region $REGION

# capture all output in three places
#exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

cleanup() {
    local code=$?
	  echo $1
	  [ -e ${EBS_DEVICE} ] && [ -n "${VOL}" ] && {
		    aws ec2 detach-volume --volume-id $VOL
		    aws ec2 delete-volume --volume-id $VOL
	  }
    [[ $code -ne 0 ]] && exit $code
    # instance is started with implicit termination
    # shutdown -P now
    exit 0 #while debugging
}

trap 'cleanup "unexpected error"' ERR
trap 'cleanup "completed normally"' EXIT


# Build an EC2 bundle and upload/register it to Amazon.
BUCKET=mirage-blog

# Make name unique to avoid registration clashes
# and sortable so we can rollback if necessary
MNT=/mnt
SUDO=sudo
IMG=${NAME}.img
APP=mirage-os.xen

BUILDER=`curl http://169.254.169.254/latest/meta-data/instance-id`

# Primarily cribbed from https://gist.github.com/yomimono/9559263
# Read more about this process here https://mirage.io/wiki/xen-boot

# KERNEL is ec2-describe-images -o amazon --region ${REGION} -F "manifest-location=*pv-grub-hd0*" -F "architecture=x86_64" | tail -1 | cut -f2
# Also obtained from http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/UserProvidedKernels.html
KERNEL=aki-919dcaf8 #us-east-1

echo fetch unikernel
aws s3 cp ${UNIKERNEL_S3_URI} ${APP}

echo makng an EBS volume of smallest size to hold unikernel boot image
ZONE=`aws ec2 describe-instances --instance-id $BUILDER | grep AvailabilityZone | sed "s/.*\(${REGION}\w\)\".*/\1/"`
VOL=`aws ec2 create-volume --size 1 --availability-zone ${ZONE} | grep VolumeId | sed 's/.*\(vol-.*\)".*/\1/'`
if [ -z "$VOL" ]; then
	  cleanup "Failed to create an EBS volume."
fi

EBS_DEVICE='/dev/xvdh'
VOL_RETRY=0
while true; do
    [ $VOL_RETRY -lt 10 ] || exit -1
    echo "waiting for volume to become available, attempt $[$VOL_RETRY + 1]"
    sleep 2
    VOL_STATE=`aws ec2 describe-volumes --volume-id $VOL | grep State | sed "s/^[ \t]*\"State\": \"\(.*\)\".*/\1/"`
    [ "$VOL_STATE" = "available" ] && break
    echo "volume $VOL not yet available, current status: $VOL_STATE"
    VOL_RETRY=$[$VOL_RETRY + 1]
done

echo attaching volume to builder instance
aws ec2 attach-volume --volume-id $VOL --instance-id $BUILDER --device $EBS_DEVICE
[ $? -ne 0 ] && {
	  cleanup "Couldn't attach the EBS volume to this instance."
}

echo waiting for block device
[ ! -e ${EBS_DEVICE} ] && sleep 2
[ ! -e ${EBS_DEVICE} ] && sleep 2
[ ! -e ${EBS_DEVICE} ] && sleep 2

echo mounting block device
${SUDO} mkfs.ext2 $EBS_DEVICE -F
${SUDO} mount -t ext2 ${EBS_DEVICE} $MNT

echo preparing image
${SUDO} mkdir -p ${MNT}/boot/grub
echo default 0 > menu.lst
echo timeout 1 >> menu.lst
echo title Mirage >> menu.lst
echo " root (hd0)" >> menu.lst
echo " kernel /boot/mirage-os.gz" >> menu.lst
${SUDO} mv menu.lst ${MNT}/boot/grub/menu.lst
${SUDO} sh -c "gzip -c ${APP} > ${MNT}/boot/mirage-os.gz"
${SUDO} umount -d ${MNT}

echo creating EBS volume snapshot
SNAPSHOT_ID=`aws ec2 create-snapshot --volume-id $VOL | grep SnapshotId | sed 's/.*\(snap-.*\)".*/\1/'`
SNAP_RETRY=0
while true; do
    [ $SNAP_RETRY -lt 10 ] || exit -1
    echo "waiting for volume to become available, attempt $[$SNAP_RETRY + 1]"
    sleep 2
    SNAP_STATE=`aws ec2 describe-snapshots --snapshot-id ${SNAPSHOT_ID} | grep State | sed "s/^[ \t]*\"State\": \"\(.*\)\".*/\1/"`
    [ "$SNAP_STATE" = "completed" ] && break
    echo "snapshot $SNAPSHOT_ID not yet completed, current status: $SNAP_STATE"
    SNAP_RETRY=$[$SNAP_RETRY + 1]
done


OLDID=`aws ec2 describe-images --owners self --filters Name=name,Values=mirage-blog | grep ImageId | sed 's/.*ami-\(.*\)",/ami-\1/'`
if [ -n "${OLDID}" ]; then
    echo "Unregistering image id $OLDID"
    aws ec2 deregister-image --image-id $OLDID || echo "image $oldid already deregistered"
fi

echo "Registering image..."
NEWID=`aws ec2 register-image --name mirage-blog --kernel $KERNEL --architecture x86_64 --block-device-mappings '[{"DeviceName":"/dev/sda1","Ebs":{"SnapshotId":"'"${SNAPSHOT_ID}"'","VolumeSize":8}}]' --root-device-name '/dev/sda1' | awk '{print $2}' | sed 's/"\(.*\)"/\1/'`
# --virtualization-type hvm ???
[ -z "${NEWID}" ] && {
	  echo "Retrying snapshot..."
	  sleep 5
    NEWID=`aws ec2 register-image --name mirage-blog --kernel $KERNEL --architecture x86_64 --block-device-mappings '[{"DeviceName":"/dev/sda1","Ebs":{"SnapshotId":"'"${SNAPSHOT_ID}"'","VolumeSize":8}}]' --root-device-name '/dev/sda1' | awk '{print $2}' | sed 's/"\(.*\)"/\1/'`
}

echo "Running instance"
aws ec2 run-instances --instance-type t1.micro --image-id $NEWID --instance-initiated-shutdown-behavior terminate --dry-run

# CNAME swap -- should wait for boot, but it's so fast... confirm port 80
