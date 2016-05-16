
# instance is started with implicit termination
# trap 'shutdown -P now' 0

# Build an EC2 bundle and upload/register it to Amazon.
BUCKET=mirage-blog
REGION=us-east-1

# Make name unique to avoid registration clashes
# and sortable so we can rollback if necessary
MNT=/tmp/mirage-ec2
SUDO=sudo
IMG=${NAME}.img

set -e

# KERNEL is ec2-describe-images -o amazon --region ${REGION} -F "manifest-location=*pv-grub-hd0*" -F "architecture=x86_64" | tail -1 | cut -f2
# Also obtained from http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/UserProvidedKernels.html
KERNEL=aki-919dcaf8 #us-east-1

${SUDO} mkdir -p ${MNT}
rm -f ${IMG}
dd if=/dev/zero of=${IMG} bs=1M count=5
${SUDO} mke2fs -F -j ${IMG}
${SUDO} mount -o loop ${IMG} ${MNT}

${SUDO} mkdir -p ${MNT}/boot/grub
echo default 0 > menu.lst
echo timeout 1 >> menu.lst
echo title Mirage >> menu.lst
echo " root (hd0)" >> menu.lst
echo " kernel /boot/mirage-os.gz" >> menu.lst
${SUDO} mv menu.lst ${MNT}/boot/grub/menu.lst
${SUDO} sh   -c "gzip -c $APP > ${MNT}/boot/mirage-os.gz"
${SUDO} umount -d ${MNT}

rm -rf ec2_tmp
mkdir ec2_tmp
echo Bundling image...
IMG_BUNDLE_KEY=img-bundling-key.pem
openssl genrsa 2048 > ${IMG_BUNDLE_KEY} #we will never unbundle, so just make it up
aws s3 cp s3://mirage-blog/bundle-signing-cert.pem cert.pem
ec2-bundle-image -i ${IMG} -k ${IMG_BUNDLE_KEY} -c cert.pem -u ${AWS_USER_ID} -d ec2_tmp -r x86_64 --kernel ${KERNEL}

echo Uploading image...
ec2-upload-bundle -b ${BUCKET} -m ec2_tmp/${IMG}.manifest.xml --location US

echo Registering image...
oldid=`aws ec2 describe-images --owners self --filters Name=name,Values=mirage-blog* | grep ImageId | sed 's/.*ami-\(.*\)",/ami-\1/'`
aws ec2 deregister-image --image-id $id
id=`aws ec2 register-image ${BUCKET}/${IMG}.manifest.xml -n ${NAME} --region ${REGION} | awk '{print $2}'`

aws ec2 run-instances --instance-type t2.nano --image-id $id --region us-east-1 --instance-initiated-shutdown-behavior terminate

# CNAME swap -- should wait for boot, but it's so fast... confirm port 80
#shutdown -P now
