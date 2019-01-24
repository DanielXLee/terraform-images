FROM amd64/alpine:3.8
MAINTAINER "Conductor Team <lixin8611@gmail.com>"

ENV PLUGIN_ARCH=amd64
COPY pkg/plugin/linux_${PLUGIN_ARCH} /Linux_${PLUGIN_ARCH}
COPY pkg/plugin/darwin_${PLUGIN_ARCH} /Darwin_${PLUGIN_ARCH}
