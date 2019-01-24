#!/usr/bin/env bash

# 1. Checkout terraform source code and build binary
function build_terraform() {
  git clone https://github.com/hashicorp/terraform.git
  pushd terraform
  git checkout v${terraform_version}

  docker run --rm -v $(pwd):/go/src/github.com/hashicorp/terraform \
    -w /go/src/github.com/hashicorp/terraform \
    -e XC_OS="linux darwin" -e XC_ARCH="amd64 ppc64le s390x" \
    golang:latest \
    bash -c "apt-get update && apt-get install -y zip && make bin"
  cp -r pkg ../
  popd
}

#2. Build terraform docker images
function build_terraform_images() {
  docker build -t conductor/terraform-amd64:0.11.10 .
  docker build -f Dockerfile-ppc64le -t conductor/terraform-ppc64le:0.11.10 .
  docker build -f Dockerfile-s390x -t conductor/terraform-s390x:0.11.10 .
}

#3. Push terraform docker images
function push_terraform_images() {
  docker push conductor/terraform-amd64:0.11.10
  docker push conductor/terraform-ppc64le:0.11.10
  docker push conductor/terraform-s390x:0.11.10
}


terraform_version=0.11.10
[[ -d working_dir ]] && rm -rf working_dir/* || mkdir working_dir
pushd working_dir
build_terraform
build_terraform_images
#push_terraform_images
popd
cd plugins;./build-plugin.sh
