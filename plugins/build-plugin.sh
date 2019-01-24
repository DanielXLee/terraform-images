#!/usr/bin/env bash

# Build Fyre Plugin
function build_fyre_plugin() {
  echo "Building Fyre Plugin..."
  local fyre_plugin_version=1.1.1
  IBM_GITHUB_USER=${IBM_GITHUB_USER:-}
  IBM_GITHUB_TOKEN=${IBM_GITHUB_TOKEN:-}
  if [[ "X${IBM_GITHUB_USER}" != "X" && "X${IBM_GITHUB_TOKEN}" != "X" ]]; then
    git clone https://${IBM_GITHUB_USER}:${IBM_GITHUB_TOKEN}@github.ibm.com/bhwarren/terraform-fyre.git
    pushd terraform-fyre
    git checkout v${fyre_plugin_version}
    for os in linux darwin; do
      for arch in amd64 ppc64le s390x; do
        [[ ("$os" == "darwin" && "$arch" == "ppc64le") || ("$os" == "darwin" && "$arch" == "s390x") ]] && continue
        docker run --rm -v $(pwd):/go/src/terraform-fyre \
        -w /go/src/terraform-fyre \
        -e GOOS=${os} -e GOARCH=${arch} golang:latest bash -c "\
        apt-get update && apt-get install -y zip && \
        go get github.com/tmc/scp && \
        go get github.com/spf13/cobra && \
        go get -u golang.org/x/crypto/... && \
        go get github.com/hashicorp/terraform && \
        go build -o terraform-provider-fyre_${arch}"
        cp terraform-provider-fyre_${arch} ../pkg/${os}_${arch}/terraform-provider-fyre
      done
    done
    popd
  else
    echo "IBM_GITHUB_USER or IBM_GITHUB_TOKEN does not existing, ignore fyre plugin build."
  fi
}

## Build other build-in plugins, find more providers: https://github.com/terraform-providers
function build_public_plugin() {
  echo "Building public terraform plugins..."
  for os in linux darwin; do
    for plugin in null template random tls local openstack vsphere aws; do
      git clone https://github.com/terraform-providers/terraform-provider-${plugin}.git
      pushd terraform-provider-${plugin}
      for arch in amd64 ppc64le s390x; do
        [[ ("$os" == "darwin" && "$arch" == "ppc64le") || ("$os" == "darwin" && "$arch" == "s390x") ]] && continue
        docker run --rm -v $(pwd):/go/src/github.com/terraform-providers/terraform-provider-${plugin} \
        -w /go/src/github.com/terraform-providers/terraform-provider-${plugin} \
        -e GOOS=${os} -e GOARCH=${arch} golang:latest bash -c "\
        apt-get update && \
        apt-get install -y zip && make build && \
        [[ -f /go/bin/terraform-provider-${plugin} ]] && \
        cp /go/bin/terraform-provider-${plugin} terraform-provider-${plugin}-${arch} || \
        cp /go/bin/${os}_${arch}/terraform-provider-${plugin} terraform-provider-${plugin}-${arch}"
        cp terraform-provider-${plugin}-${arch} ../pkg/${os}_${arch}/terraform-provider-${plugin}
      done
      popd
    done
  done
}

# Build and push plugin images
function build_plugin_images() {
  docker build -t conductor/terraform-plugins-amd64:1.0 .
  docker build -f Dockerfile-ppc64le -t conductor/terraform-plugins-ppc64le:1.0 .
  docker build -f Dockerfile-s390x -t conductor/terraform-plugins-s390x:1.0 .
}

# Push and push plugin images
function push_plugin_images() {
  docker push conductor/terraform-plugins-amd64:1.0
  docker push conductor/terraform-plugins-ppc64le:1.0
  docker push conductor/terraform-plugins-s390x:1.0
}

# Build Terraform Plugin
[[ -d working_dir ]] && rm -rf working_dir/* || mkdir -p working_dir/pkg
pushd working_dir
cd pkg;mkdir linux_amd64 linux_ppc64le linux_s390x darwin_amd64
build_fyre_plugin
build_public_plugin
build_plugin_images
#push_plugin_images
popd
