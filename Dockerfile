FROM amd64/alpine:3.8
MAINTAINER "Conductor Team <lixin8611@gmail.com>"

COPY pkg/linux_amd64/terraform /pkg/terraform
COPY pkg/plugins/linux_amd64/* /pkg/plugins/
