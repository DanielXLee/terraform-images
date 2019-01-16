#!/usr/bin/env bash

# Build Terraform Plugin
## Build Fyre Plugin
[[ -d working_dir ]] && rm -rf working_dir/* || mkdir working_dir
pushd working_dir
mkdir linux_amd64 linux_ppc64le linux_s390x
#1. Build fyre plugin binary
git clone https://lixinxa:878d7994b25bd68c4ff298fde7b07da7dcb209e1@github.ibm.com/bhwarren/terraform-fyre.git
pushd terraform-fyre
git checkout v1.1.1
for arch in amd64 ppc64le s390x; do
  docker run --rm -v $(pwd):/go/src/terraform-fyre \
  -w /go/src/terraform-fyre \
  -e GOOS=linux -e GOARCH=${arch} golang:latest bash -c "\
  apt-get update && apt-get install -y zip && \
  go get github.com/tmc/scp && \
  go get github.com/spf13/cobra && \
  go get -u golang.org/x/crypto/... && \
  go get github.com/hashicorp/terraform && \
  go build -o terraform-provider-fyre_${arch}"
  cp terraform-provider-fyre_${arch} ../linux_${arch}/terraform-provider-fyre
done
popd

## Build other build-in plugins
for plugin in null template random tls local; do
  git clone https://github.com/terraform-providers/terraform-provider-${plugin}.git
  pushd terraform-provider-${plugin}
  for arch in amd64 ppc64le s390x; do
    docker run --rm -v $(pwd):/go/src/github.com/terraform-providers/terraform-provider-${plugin} \
    -w /go/src/github.com/terraform-providers/terraform-provider-${plugin} \
    -e GOOS=linux -e GOARCH=${arch} golang:latest bash -c "\
    apt-get update && \
    apt-get install -y zip && make build && \
    [[ -f /go/bin/terraform-provider-${plugin} ]] && \
    cp /go/bin/terraform-provider-${plugin} terraform-provider-${plugin}-${arch} || \
    cp /go/bin/linux_${arch}/terraform-provider-${plugin} terraform-provider-${plugin}-${arch}"
    cp terraform-provider-${plugin}-${arch} ../linux_${arch}/terraform-provider-${plugin}
  done
  popd
done
popd

# Build and push plugin images
docker build -t conductor/terraform-plugins-amd64:1.0 .
docker push conductor/terraform-plugins-amd64:1.0
docker build -f Dockerfile-ppc64le -t conductor/terraform-plugins-ppc64le:1.0 .
docker push conductor/terraform-plugins-ppc64le:1.0
docker build -f Dockerfile-s390x -t conductor/terraform-plugins-s390x:1.0 .
docker push conductor/terraform-plugins-s390x:1.0
