#!/usr/bin/env bash

#1. Build terraform and plugin binary
function build_binary() {
  docker run --rm --net=host -v $(pwd):/go -w /go \
  -e PLUGIN="${PLUGIN}" \
  -e IBM_GITHUB_USER="${IBM_GITHUB_USER}" \
  -e IBM_GITHUB_TOKEN="${IBM_GITHUB_TOKEN}" \
  -e XC_ARCH="${XC_ARCH}" \
  -e XC_OS="${XC_OS}" \
  -e TERRAFORM_VERSION="${TERRAFORM_VERSION}" \
  -e PROVIDERS="${PROVIDERS}" \
  golang:latest \
  bash -c "apt-get update && apt-get install -y zip && bash /go/xc_build.sh"
}

#2. Build terraform and plugin images
function build_images() {
  # Build terraform images
  docker build -f Dockerfile -t conductor/terraform-amd64:${TERRAFORM_VERSION} .
  docker build -f Dockerfile-ppc64le -t conductor/terraform-ppc64le:${TERRAFORM_VERSION} .
  docker build -f Dockerfile-s390x -t conductor/terraform-s390x:${TERRAFORM_VERSION} .
}

#3. Push images to docker hub
function push_images() {
  # Push terraform docker images
  docker push conductor/terraform-amd64:${TERRAFORM_VERSION}
  docker push conductor/terraform-ppc64le:${TERRAFORM_VERSION}
  docker push conductor/terraform-s390x:${TERRAFORM_VERSION}
}

#4. Build multi arch images
function multi_arch() {
  if [[ ! -f manifest-tool ]]; then
    wget https://github.com/estesp/manifest-tool/releases/download/v0.7.0/manifest-tool-linux-$(uname -m | sed 's/x86_64/amd64/g') -O manifest-tool
    chmod +x manifest-tool
  fi
  for image in terraform:${TERRAFORM_VERSION}; do
    ./manifest-tool push from-args \
        --platforms linux/amd64,linux/ppc64le,linux/s390x \
        --template conductor/${image//:/-ARCH:} \
        --target conductor/$image \
        --ignore-missing
  done
}

function run() {
  case $CMD in
  bin)
    build_binary
    ;;
  image)
    build_images
    ;;
  push)
    push_images
    ;;
  multi)
    multi_arch
    ;;
  *)
    build_binary
    build_images
    push_images
    multi_arch
    ;;
  esac
}

function usage () {
  local script="${0##*/}"
  cat <<-EOF
Usage: ${script} <[Option]>

Options:
  -h help                  Display this help and exit
  -c command               Run command (bin, image, push, multi)
     [bin]                 Build terraform and plugin binary
     [image]               Build terraform docker images
     [push]                Push terraform docker images
     [multi]               Build terraform multiple arch docker images

Examples:
Build binary
  ./${script} -c bin
Build image
  ./${script} -c image
Push image
  ./${script} -c push
Build multi image
  ./${script} -c multi
Build all
  ./${script}
EOF
}

#----------------------------------- Main -------------------------------------#
while getopts :c:h opt
do
  case "$opt" in
  h)
    usage
    exit 0
    ;;
  c)
    CMD="$OPTARG"
    ;;
  ?)
    usage
    exit 0
    ;;
  esac
done

PLUGIN=${PLUGIN:-}
IBM_GITHUB_USER=${IBM_GITHUB_USER:-}
IBM_GITHUB_TOKEN=${IBM_GITHUB_TOKEN:-}
XC_ARCH=${XC_ARCH:-"ppc64le amd64 s390x"}
XC_OS=${XC_OS:-"linux"}
TERRAFORM_VERSION=${TERRAFORM_VERSION:-0.11.13}
TERRAFORM_PLUGIN_VERSION=${TERRAFORM_PLUGIN_VERSION:-1.1}
TERRAFORM_PLUGIN_FYRE_VERSION=${TERRAFORM_PLUGIN_FYRE_VERSION:-1.1.1}
PROVIDERS=${PROVIDERS:-"null template random tls local openstack vsphere"}
run
