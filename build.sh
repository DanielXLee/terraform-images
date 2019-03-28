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

function build_pkgs() {
  [[ -d dist ]] && rm -rf dist || mkdir dist
  cp -r pkg/plugin/* dist/
  cp -r pkg/linux_* dist/
  cp -r pkg/darwin_* dist/
  for pkg in $(ls dist); do
    zip ${pkg}.zip dist/${pkg}/*
  done
}

#2. Build terraform and plugin images
function build_images() {
  # Build terraform images
  docker build -f Dockerfile -t conductor/terraform-amd64:${TERRAFORM_VERSION} pkg
  docker build -f Dockerfile-ppc64le -t conductor/terraform-ppc64le:${TERRAFORM_VERSION} pkg
  docker build -f Dockerfile-s390x -t conductor/terraform-s390x:${TERRAFORM_VERSION} pkg
  # Build terraform plugin images
  docker build -f plugins/Dockerfile -t conductor/terraform-plugins-amd64:${TERRAFORM_PLUGIN_VERSION} pkg/plugins
  docker build -f plugins/Dockerfile-ppc64le -t conductor/terraform-plugins-ppc64le:${TERRAFORM_PLUGIN_VERSION} pkg/plugins
  docker build -f plugins/Dockerfile-s390x -t conductor/terraform-plugins-s390x:${TERRAFORM_PLUGIN_VERSION} pkg/plugins
}

#3. Push images to docker hub
function push_images() {
  # Push terraform docker images
  docker push conductor/terraform-amd64:${TERRAFORM_VERSION}
  docker push conductor/terraform-ppc64le:${TERRAFORM_VERSION}
  docker push conductor/terraform-s390x:${TERRAFORM_VERSION}
  # Push terraform plugin docker images
  docker push conductor/terraform-plugins-amd64:${TERRAFORM_PLUGIN_VERSION}
  docker push conductor/terraform-plugins-ppc64le:${TERRAFORM_PLUGIN_VERSION}
  docker push conductor/terraform-plugins-s390x:${TERRAFORM_PLUGIN_VERSION}
}

#4. Build multi arch images
function multi_arch() {
  if [[ ! -f manifest-tool ]]; then
    wget https://github.com/estesp/manifest-tool/releases/download/v0.7.0/manifest-tool-linux-$(uname -m | sed 's/x86_64/amd64/g') -O manifest-tool
    chmod +x manifest-tool
  fi
  for image in terraform:${TERRAFORM_VERSION} terraform-plugins:${TERRAFORM_PLUGIN_VERSION}; do
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
  pkg)
    build_pkgs
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
     [pkg]                 Build terraform and plugin zip package
     [image]               Build terraform and plugin docker images
     [push]                Push terraform and plugin docker images
     [multi]               Build terraform and plugin multiple arch docker images

Examples:
Build binary
  ./${script} -c bin
Build zip package
  ./${script} -c pkg
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
TERRAFORM_VERSION=${TERRAFORM_VERSION:-0.11.10}
TERRAFORM_PLUGIN_VERSION=${TERRAFORM_PLUGIN_VERSION:-1.0}
PROVIDERS=${PROVIDERS:-"null template random tls local openstack vsphere"}
run
