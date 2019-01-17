FROM amd64/alpine:3.8
MAINTAINER "Conductor Team <lixin8611@gmail.com>"

ENV TERRAFORM_ARCH=amd64

COPY working_dir/linux_${TERRAFORM_ARCH}/terraform /terraform
