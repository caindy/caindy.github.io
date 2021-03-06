# install mirage, build the unikernel, upload to S3 and start a builder instance

NEWNAME=`date '+%Y-%m-%d-%H-%M-%s'`
set -e
bash -ex ../.travis-mirage.sh
UNIKERNEL_S3_URI="s3://mirage-blog/${NEWNAME}.xen"
aws s3 cp mir-www.xen ${UNIKERNEL_S3_URI}

# write script that will run on boot of builder instance
echo "#!/usr/bin/env bash" > ec2deploy.sh
echo "AWS_USER_ID=${AWS_USER_ID}" >> ec2deploy.sh
#echo "AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}" >> ec2deploy.sh
#echo "AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}" >> ec2deploy.sh
echo "UNIKERNEL_S3_URI=${UNIKERNEL_S3_URI}" >> ec2deploy.sh
echo "NAME=mirage-blog-${NEWNAME}" >> ec2deploy.sh
echo "APP=mirage-blog" >> ec2deploy.sh
cat ec2.sh >> ec2deploy.sh

#run builder instance
AMZN_LINUX=ami-f5f41398
aws ec2 run-instances --user-data file://ec2deploy.sh --instance-type t2.nano --image-id ${AMZN_LINUX} --region us-east-1 --instance-initiated-shutdown-behavior terminate --security-groups blog-builder-sg --key-name mirage-blog-image-builder-keys --iam-instance-profile Name=mirage-blog-image-builder
