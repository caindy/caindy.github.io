# install mirage, build the unikernel, upload to S3 and start a builder instance

NEWNAME=`date '+%Y-%m-%d-%H-%M-%s'`
set -e
bash -ex ../.travis-mirage.sh
aws s3 cp mir-www.xen "s3://mirage-blog/${NEWNAME}.xen"
echo "#!/usr/bin/env bash" > ec2deploy.sh
echo "\n" >> ec2deploy.sh
echo "AWS_USER_ID=${AWS_USER_ID}" >> ec2deploy.sh
#echo "AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}" >> ec2deploy.sh
#echo "AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}" >> ec2deploy.sh
echo "NAME=mirage-blog-${NEWNAME}" >> ec2deploy.sh
cat ec2.sh >> ec2deploy.sh
AMZN_LINUX=ami-f5f41398
aws ec2 run-instances --user-data file://ec2deploy.sh --instance-type t2.nano --image-id ${AMZN_LINUX} --region us-east-1 --instance-initiated-shutdown-behavior terminate --security-groups blog-builder-sg
