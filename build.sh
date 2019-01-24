#!/usr/bin/env bash

#1. Build terraform and plugin binary
function build_binary() {
  docker run --rm -v $(pwd):/go -w /go \
  -e PLUGIN="${PLUGIN}" \
  -e IBM_GITHUB_USER="${IBM_GITHUB_USER}" \
  -e IBM_GITHUB_TOKEN="${IBM_GITHUB_TOKEN}" \
  -e XC_ARCH="${XC_ARCH}" \
  -e XC_OS="${XC_OS}" \
  -e PROVIDERS="${PROVIDERS}" \
  golang:latest \
  bash -c "apt-get update && apt-get install -y zip && bash /go/xc_build.sh"
}

#2. Build terraform and plugin images
function build_images() {
  # Build terraform images
  docker build -t conductor/terraform-amd64:0.11.10 .
  docker build -f Dockerfile-ppc64le -t conductor/terraform-ppc64le:0.11.10 .
  docker build -f Dockerfile-s390x -t conductor/terraform-s390x:0.11.10 .
  # Build terraform plugin images
  docker build -f plugins/Dockerfile -t conductor/terraform-plugins-amd64:1.0 .
  docker build -f plugins/Dockerfile-ppc64le -t conductor/terraform-plugins-ppc64le:1.0 .
  docker build -f plugins/Dockerfile-s390x -t conductor/terraform-plugins-s390x:1.0 .
}

#3. Push images to docker hub
function push_images() {
  # Push terraform docker images
  docker push conductor/terraform-amd64:0.11.10
  docker push conductor/terraform-ppc64le:0.11.10
  docker push conductor/terraform-s390x:0.11.10
  # Push terraform plugin docker images
  docker push conductor/terraform-plugins-amd64:1.0
  docker push conductor/terraform-plugins-ppc64le:1.0
  docker push conductor/terraform-plugins-s390x:1.0
}

#4. Build multi arch images
function multi_arch() {
  if [[ ! -f manifest-tool ]]; then
    wget https://github.com/estesp/manifest-tool/releases/download/v0.7.0/manifest-tool-linux-$(uname -m | sed 's/x86_64/amd64/g') -O manifest-tool
    chmod +x manifest-tool
  fi
  for image in terraform:0.11.10 terraform-plugins:1.0; do
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
     [image]               Build terraform and plugin docker images
     [push]                Push terraform and plugin docker images
     [multi]               Build terraform and plugin multiple arch docker images

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
XC_OS=${XC_OS:-"linux darwin"}
PROVIDERS=${PROVIDERS:-"null template random tls local openstack vsphere"}
run
