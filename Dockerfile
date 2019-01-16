FROM amd64/alpine:3.8
MAINTAINER "Conductor Team <lixin8611@gmail.com>"

ENV TERRAFORM_ARCH=amd64

COPY pkg/linux_${TERRAFORM_ARCH}/terraform /terraform
