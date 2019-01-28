FROM amd64/alpine:3.8
MAINTAINER "Conductor Team <lixin8611@gmail.com>"

ENV TERRAFORM_ARCH=amd64
COPY linux_${TERRAFORM_ARCH} /Linux_${TERRAFORM_ARCH}
COPY darwin_${TERRAFORM_ARCH} /Darwin_${TERRAFORM_ARCH}
