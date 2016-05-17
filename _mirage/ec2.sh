
# capture all output in three places
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

cleanup() {
	  echo $1
	  [ -e ${EBS_DEVICE} ] && [ -n "${VOL}" ] && [ -n "${REGION}" ] && {
		    aws ec2 detach-volume --volume-id $VOL --region $REGION
		    aws ec2 delete-volume --volume-id $VOL --region $REGION
	  }
    # instance is started with implicit termination
    # shutdown -P now
    [ ERR -ne 0 ] && exit ERR
	  exit 1
}

trap 'cleanup "unexpected error"' ERR

# Build an EC2 bundle and upload/register it to Amazon.
BUCKET=mirage-blog
REGION=us-east-1

# Make name unique to avoid registration clashes
# and sortable so we can rollback if necessary
MNT=/tmp/mirage-ec2
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
ZONE=`aws ec2 describe-instances --instance-id $BUILDER --region ${REGION} | grep AvailabilityZone | sed "s/.*\(${REGION}\w\)\".*/\1/"`
VOL=`aws ec2 create-volume --size 1 --region ${REGION} --availability-zone ${ZONE} | grep VolumeId | sed 's/.*\(vol-.*\)".*/\1/'`
if [ "$VOL" = "" ]; then
	  cleanup "Failed to create an EBS volume."
fi

echo attaching volume to builder instance
EBS_DEVICE='/dev/xvdh'
aws ec2 attach-volume --volume-id $VOL --instance-id $BUILDER --device $EBS_DEVICE --region $REGION
[ $? -ne 0 ] && {
	  cleanup "Couldn't attach the EBS volume to this instance."
}

echo waiting for block device
[ ! -e ${EBS_DEVICE} ] && sleep 2
[ ! -e ${EBS_DEVICE} ] && sleep 2
[ ! -e ${EBS_DEVICE} ] && sleep 2

echo mounting block device
${SUDO} mkfs.ext2 $EBS_DEVICE
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
SNAPSHOT_ID=`aws ec2 create-snapshot --region $REGION --volume-id $VOL | grep SnapshotId | sed 's/.*\(snap-.*\)".*/\1/'`
[ -z "{$SNAPSHOT_ID}" ] && cleanup "Couldn't make a snapshot of the EBS volume."

OLDID=`aws ec2 describe-images --owners self --region ${REGION} --filters Name=name,Values=mirage-blog | grep ImageId | sed 's/.*ami-\(.*\)",/ami-\1/'`
if [ -n "${OLDID}" ]; then
    echo "Unregistering image id $OLDID"
    aws ec2 deregister-image --image-id $OLDID --region ${REGION} || echo "image $oldid already deregistered"
fi

echo "Registering image..."
NEWID=`aws ec2 register-image --name mirage-blog --region ${REGION} --kernel $KERNEL --snapshot-id $SNAPSHOT_ID --architecture x86_64" | awk '{print $2}' | sed 's/"\(.*\)"/\1/'`

[ -z "${NEWID}" ] && {
	  echo "Retrying snapshot..."
	  sleep 5
    NEWID=`aws ec2 register-image --name mirage-blog --region ${REGION} --kernel $KERNEL --snapshot-id $SNAPSHOT_ID --architecture x86_64" | awk '{print $2}' | sed 's/"\(.*\)"/\1/'`
}

echo "Running instance"
aws ec2 run-instances --instance-type t2.nano --image-id $id --region ${REGION} --instance-initiated-shutdown-behavior terminate --dry-run

cleanup "Instance started successfully"
# CNAME swap -- should wait for boot, but it's so fast... confirm port 80
# ${SUDO} shutdown -P now
